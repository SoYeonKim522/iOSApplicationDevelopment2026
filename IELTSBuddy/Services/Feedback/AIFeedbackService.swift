//
//  AIFeedbackService.swift
//  IELTSBuddy
//

import Foundation

enum AIFeedbackServiceError: LocalizedError {
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
                return "Request failed (\(statusCode)): \(message)"
            }
            return "Request failed with HTTP status \(statusCode)."
        case .emptyModelContent:
            return "The model returned no content to decode."
        case .decodingFailed(let underlying):
            return "Failed to decode feedback JSON: \(underlying.localizedDescription)"
        case .networkFailed(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

final class AIFeedbackService: AIFeedbackProviding {
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

    func fetchFeedback(question: String, userAnswer: String) async throws -> AIFeedback {
        let apiKey: String
        do {
            apiKey = try apiKeyProvider()
        } catch {
            throw AIFeedbackServiceError.missingAPIKey
        }

        guard let url = Self.makeEndpointURL(apiKey: apiKey) else {
            throw AIFeedbackServiceError.invalidURL
        }

        let systemInstruction = Self.buildSystemInstruction()
        let userText = Self.buildUserContent(question: question, userAnswer: userAnswer)

        let body = GeminiGenerateContentRequest(
            systemInstruction: .init(parts: [.init(text: systemInstruction)]),
            contents: [
                .init(role: "user", parts: [.init(text: userText)]),
            ],
            generationConfig: .init(responseMimeType: "application/json")
        )

        let encoder = JSONEncoder()
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw AIFeedbackServiceError.invalidResponse
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
            throw AIFeedbackServiceError.networkFailed(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIFeedbackServiceError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = Self.extractGeminiErrorMessage(from: data)
            throw AIFeedbackServiceError.httpFailure(statusCode: http.statusCode, message: message)
        }

        let geminiResponse: GeminiGenerateContentResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        } catch {
            throw AIFeedbackServiceError.decodingFailed(underlying: error)
        }

        guard let rawContent = geminiResponse.candidates?.first?.content?.parts?.first?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawContent.isEmpty
        else {
            throw AIFeedbackServiceError.emptyModelContent
        }

        let normalizedJSON = Self.stripMarkdownCodeFence(from: rawContent)
        guard let jsonData = normalizedJSON.data(using: .utf8) else {
            throw AIFeedbackServiceError.emptyModelContent
        }

        do {
            return try JSONDecoder().decode(AIFeedback.self, from: jsonData)
        } catch {
            throw AIFeedbackServiceError.decodingFailed(underlying: error)
        }
    }

    private static func makeEndpointURL(apiKey: String) -> URL? {
        var components = URLComponents(string: endpointBase)
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
        ]
        return components?.url
    }

    private static func buildSystemInstruction() -> String {
        """
        You are an expert IELTS Speaking examiner. Evaluate the learner's transcribed answer using official IELTS criteria: Fluency and Coherence, Lexical Resource, Grammatical Range and Accuracy, and Pronunciation (infer pronunciation quality only from the text where reasonable, and note limitations briefly in feedback if needed).

        You MUST respond with ONLY a single JSON object—no markdown, no code fences, no commentary before or after the JSON. The JSON must be valid UTF-8 and parseable by Swift's JSONDecoder.

        The JSON MUST use exactly these camelCase keys and shapes (types matter):
        - "questionText": string — echo the examiner question exactly as provided in the user message.
        - "userAnswer": string — echo the learner's answer exactly as provided in the user message.
        - "overallScore": number — IELTS-style band (typically 0–9, steps of 0.5 allowed).
        - "fluencyScore": number
        - "vocabularyScore": number
        - "grammarScore": number
        - "pronunciationScore": number
        - "feedback": object with keys "strengths", "weaknesses", "ideaSuggestion" (all strings).
        - "aiCorrections": array of objects, each with "original" (string), "corrected" (string), "type" (exactly one of: "grammar", "vocabulary", "pronunciation"), and "explanation" (string; may be empty).

        CRITICAL RULE FOR aiCorrections:
            You MUST provide at least ONE item in the `aiCorrections` array. If the user's answer is perfect, provide a better, more native-sounding alternative expression and classify it as "vocabulary". NEVER return an empty array []
        
        Do not include an "id" field on the root object or on review log items (optional ids are accepted but omit them). Do not wrap the JSON in markdown.
        """
    }

    private static func buildUserContent(question: String, userAnswer: String) -> String {
        """
        QUESTION:
        \(question)

        LEARNER_ANSWER (transcript):
        \(userAnswer)
        """
    }

    private static func extractGeminiErrorMessage(from data: Data) -> String? {
        struct Envelope: Decodable {
            struct Detail: Decodable {
                let code: Int?
                let message: String?
                let status: String?
            }
            let error: Detail?
        }
        return (try? JSONDecoder().decode(Envelope.self, from: data))?.error?.message
    }

    /// Removes a leading/trailing ```json ... ``` wrapper if the model adds one despite instructions.
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

// MARK: - Gemini request DTOs

private struct GeminiGenerateContentRequest: Encodable {
    let systemInstruction: SystemInstructionPayload
    let contents: [ContentPayload]
    let generationConfig: GenerationConfigPayload

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
        case generationConfig
    }

    struct SystemInstructionPayload: Encodable {
        let parts: [PartPayload]
    }

    struct ContentPayload: Encodable {
        let role: String
        let parts: [PartPayload]
    }

    struct PartPayload: Encodable {
        let text: String
    }

    struct GenerationConfigPayload: Encodable {
        let responseMimeType: String

        enum CodingKeys: String, CodingKey {
            case responseMimeType
        }
    }
}

// MARK: - Gemini response DTOs

private struct GeminiGenerateContentResponse: Decodable {
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
