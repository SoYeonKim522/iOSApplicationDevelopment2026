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
            return "The Gemini API key is not configured. Add GEMINI_API_KEY to Secrets.plist."
        case .invalidURL:
            return "The Gemini API URL was invalid."
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

    private static let endpointBase = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    private let session: URLSession
    private let apiKeyProvider: () throws -> String

    init(
        session: URLSession = .shared,
        apiKeyProvider: @escaping () throws -> String = { try APIKeyManager.shared.geminiAPIKey() }
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

        guard let url = Self.makeEndpointURL(apiKey: apiKey) else {
            throw QuestionGeneratorServiceError.invalidURL
        }

        let categories = TopicCategory.allCases.map(\.rawValue).joined(separator: ", ")
        let systemInstruction = Self.buildSystemInstruction(topic: topic, part: part, topicCategoryAllowlist: categories)

        let body = QuestionGeminiGenerateContentRequest(
            systemInstruction: .init(parts: [.init(text: systemInstruction)]),
            contents: [
                .init(role: "user", parts: [.init(text: "Generate exactly one PracticeQuestion JSON now.")]),
            ],
            generationConfig: .init(responseMimeType: "application/json")
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
            let message = Self.extractGeminiErrorMessage(from: data)
            throw QuestionGeneratorServiceError.httpFailure(statusCode: http.statusCode, message: message)
        }

        let decoded: GeminiGenerateContentResponseEnvelope
        do {
            decoded = try JSONDecoder().decode(GeminiGenerateContentResponseEnvelope.self, from: data)
        } catch {
            throw QuestionGeneratorServiceError.decodingFailed(underlying: error)
        }

        guard let rawContent = decoded.candidates?.first?.content?.parts?.first?.text?
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

    private static func makeEndpointURL(apiKey: String) -> URL? {
        var components = URLComponents(string: endpointBase)
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components?.url
    }
    
    private static func buildSystemInstruction(
        topic: TopicCategory,
        part: PartType,
        topicCategoryAllowlist: String
    ) -> String {
        let partGuidelines = partGuidelines(for: part, topic: topic.rawValue)
        let duration = estimatedDuration(for: part)

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

    private static func estimatedDuration(for part: PartType) -> Int {
        switch part {
        case .part1: return 25
        case .part2: return 120
        case .part3: return 45
        }
    }
    

    private static func extractGeminiErrorMessage(from data: Data) -> String? {
        struct Envelope: Decodable {
            struct Detail: Decodable {
                let message: String?
            }
            let error: Detail?
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.error?.message
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

// MARK: - Gemini request / response DTOs (local to question generation)

private struct QuestionGeminiGenerateContentRequest: Encodable {
    let systemInstruction: SystemPayload
    let contents: [ContentPayload]
    let generationConfig: GenConfigPayload

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
        case generationConfig
    }

    struct SystemPayload: Encodable {
        let parts: [TextPart]
    }

    struct ContentPayload: Encodable {
        let role: String
        let parts: [TextPart]
    }

    struct TextPart: Encodable {
        let text: String
    }

    struct GenConfigPayload: Encodable {
        let responseMimeType: String

        enum CodingKeys: String, CodingKey {
            case responseMimeType
        }
    }
}

private struct GeminiGenerateContentResponseEnvelope: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}
