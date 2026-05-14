//
//  QuestionGeneratorService.swift
//  IELTSBuddy
//

import Foundation

enum QuestionGeneratorServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpFailure(statusCode: Int, message: String?)
    case emptyModelContent
    case decodingFailed(underlying: Error)
    case networkFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "The OpenAI API key is not configured. Add OPENAI_API_KEY to Secrets.plist."
        case .invalidURL:
            return "The OpenAI API URL was invalid."
        case .invalidResponse:
            return "The server response could not be interpreted."
        case .httpFailure(let statusCode, let message):
            if let message, !message.isEmpty {
                return "Question request failed (\(statusCode)): \(message)"
            }
            return "Question request failed with HTTP status \(statusCode)."
        case .emptyModelContent:
            return "The model returned no question JSON."
        case .decodingFailed(let underlying):
            return "Failed to decode question JSON: \(underlying.localizedDescription)"
        case .networkFailed(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

final class QuestionGeneratorService: QuestionGenerating {
    private static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    private static let openAIModel = "gpt-4o-mini"

    private let session: URLSession
    private let apiKeyProvider: () throws -> String

    init(
        session: URLSession = NetworkSession.makeDefault(),
        apiKeyProvider: @escaping () throws -> String = { try APIKeyManager.shared.openAIAPIKey() }
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func generateQuestion(topic: TopicCategory, part: PartType) async throws -> PracticeQuestion {
        let apiKey: String
        do {
            apiKey = try apiKeyProvider()
        } catch {
            throw QuestionGeneratorServiceError.missingAPIKey
        }

        guard let url = URL(string: Self.openAIEndpoint) else {
            throw QuestionGeneratorServiceError.invalidURL
        }

        let categories = TopicCategory.allCases.map(\.rawValue).joined(separator: ", ")
        let systemContent = Self.buildOpenAISystemInstruction(
            topic: topic,
            part: part,
            topicCategoryAllowlist: categories
        )
        let userContent = "Generate exactly one PracticeQuestion JSON now."

        let body = OpenAIChatCompletionRequest(
            model: Self.openAIModel,
            messages: [
                OpenAIChatMessage(role: "system", content: systemContent),
                OpenAIChatMessage(role: "user", content: userContent),
            ],
            responseFormat: .init(type: "json_object")
        )

        let encoder = JSONEncoder()
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw QuestionGeneratorServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw QuestionGeneratorServiceError.networkFailed(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw QuestionGeneratorServiceError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = Self.extractOpenAIErrorMessage(from: data)
            throw QuestionGeneratorServiceError.httpFailure(statusCode: http.statusCode, message: message)
        }

        let decoded: OpenAIChatCompletionResponse
        do {
            decoded = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
        } catch {
            throw QuestionGeneratorServiceError.decodingFailed(underlying: error)
        }

        guard let rawContent = decoded.choices?.first?.message?.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawContent.isEmpty
        else {
            throw QuestionGeneratorServiceError.emptyModelContent
        }

        let normalizedJSON = Self.stripMarkdownCodeFence(from: rawContent)
        guard let jsonData = normalizedJSON.data(using: .utf8) else {
            throw QuestionGeneratorServiceError.emptyModelContent
        }

        do {
            return try JSONDecoder().decode(PracticeQuestion.self, from: jsonData)
        } catch {
            throw QuestionGeneratorServiceError.decodingFailed(underlying: error)
        }
    }

    // MARK: - OpenAI helpers

    private static func buildOpenAISystemInstruction(
        topic: TopicCategory,
        part: PartType,
        topicCategoryAllowlist: String
    ) -> String {
        let core = buildSystemInstruction(topic: topic, part: part, topicCategoryAllowlist: topicCategoryAllowlist)
        return """
        \(core)

        OUTPUT FORMAT (mandatory): Respond with a single JSON object only (no markdown fences, no prose before or after). The JSON must match the PracticeQuestion schema described above and must be valid for parsing by a strict JSON decoder.
        """
    }

    private static func extractOpenAIErrorMessage(from data: Data) -> String? {
        struct Envelope: Decodable {
            struct Detail: Decodable {
                let message: String?
                let type: String?
                let code: String?
            }
            let error: Detail?
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.error?.message
    }

    // MARK: - Shared prompt helpers

    private static func buildSystemInstruction(
        topic: TopicCategory,
        part: PartType,
        topicCategoryAllowlist: String
    ) -> String {
        let partGuidelines = partGuidelines(for: part, topic: topic.rawValue)
        let duration = part.estimatedDuration

        return """
        IELTS examiner. Generate ONE \(part) question about '\(topic)'. Output valid JSON only, no markdown.

        Schema: {"text":"...","part":"\(part)","topicCategory":"<from allowlist>","estimatedDuration":\(duration)}

        topicCategory allowlist: \(topicCategoryAllowlist). Use "\(topic)" if it fits, else closest match.

        \(part) format: \(partGuidelines)
        """
    }

    private static func partGuidelines(for part: PartType, topic: String) -> String {
        switch part {
        case .part1:
            return """
            One sentence only
            Style: "Do you enjoy...?", "How often do you...?". .
            """
        case .part2:
            return """
            A cue card using EXACTLY this structure (preserve the newlines):
            "Describe [subject related to '\(topic)'].\\n\\nYou should say:\\n• [point 1]\\n• [point 2]\\n• [point 3]\\n\\nAnd explain [reflective prompt]."
            """
        case .part3:
            return """
            An analytical question linked to '\(topic)'. \
            Style: "Why do you think...?", "How has ... changed?". One sentence only.
            """
        }
    }

    private static func stripMarkdownCodeFence(from content: String) -> String {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text.removeFirst(3)
            if text.lowercased().hasPrefix("json") {
                text = String(text.dropFirst(4))
            }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.hasSuffix("```") {
                text.removeLast(3)
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - OpenAI request / response DTOs

private struct OpenAIChatCompletionRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let responseFormat: OpenAIResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct OpenAIChatMessage: Encodable {
    let role: String
    let content: String
}

private struct OpenAIResponseFormat: Encodable {
    let type: String
}

private struct OpenAIChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message?
    }
    let choices: [Choice]?
}
