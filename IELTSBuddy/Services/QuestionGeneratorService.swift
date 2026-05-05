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

final class QuestionGeneratorService {

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

    func generateQuestion(topic: String, part: String) async throws -> PracticeQuestion {
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

    private static func buildSystemInstruction(topic: String, part: String, topicCategoryAllowlist: String) -> String {
        """
        You are an expert IELTS examiner. Generate ONE realistic IELTS Speaking question for \(part) about the topic '\(topic)'.
        You MUST return strictly valid JSON matching our PracticeQuestion Codable shape (no markdown, no extra text):

        Keys (camelCase only):
        - "id": optional UUID string (omit if you prefer — the client assigns one).
        - "text": the single examiner question sentence.
        - "part": must be exactly "part1", "part2", or "part3" (prefer \(part) as requested).
        - "topicCategory": must be exactly one literal from this allowlist — \(topicCategoryAllowlist).
          Prefer "\(topic)" when it fits the learner's topic selector; otherwise pick the closest semantic match from the allowlist.
        - "estimatedDuration": integer seconds suggesting how long an answer might reasonably take for that part.

        Honour IELTS part styles: Part 1 short personalised questions; Part 2 a clear long-turn / cue-card style stem; Part 3 more analytical follow-up prompts.
        """
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
