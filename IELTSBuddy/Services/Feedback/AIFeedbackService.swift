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
            return "The OpenAI API key is not configured. Add OPENAI_API_KEY to Secrets.plist."
        case .invalidURL:
            return "The OpenAI API URL was invalid."
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
    private let session: URLSession
    private let apiKeyProvider: () throws -> String

    init(
        session: URLSession = NetworkSession.makeDefault(),
        apiKeyProvider: @escaping () throws -> String = { try APIKeyManager.shared.openAIAPIKey() }
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

        guard let url = URL(string: OpenAIConfig.endpoint) else {
            throw AIFeedbackServiceError.invalidURL
        }

        let systemContent = Self.buildOpenAISystemInstruction()
        let userContent = Self.buildUserContent(question: question, userAnswer: userAnswer)

        let body = OpenAIChatCompletionRequest(
            model: OpenAIConfig.feedbackModel,
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
            throw AIFeedbackServiceError.invalidResponse
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
            throw AIFeedbackServiceError.networkFailed(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIFeedbackServiceError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = OpenAIHelpers.extractOpenAIErrorMessage(from: data)
            throw AIFeedbackServiceError.httpFailure(statusCode: http.statusCode, message: message)
        }

        let openAIResponse: OpenAIChatCompletionResponse
        do {
            openAIResponse = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
        } catch {
            throw AIFeedbackServiceError.decodingFailed(underlying: error)
        }

        guard let rawContent = openAIResponse.choices?.first?.message?.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawContent.isEmpty
        else {
            throw AIFeedbackServiceError.emptyModelContent
        }

        let normalizedJSON = OpenAIHelpers.stripMarkdownCodeFence(from: rawContent)
        guard let jsonData = normalizedJSON.data(using: .utf8) else {
            throw AIFeedbackServiceError.emptyModelContent
        }

        do {
            return try JSONDecoder().decode(AIFeedback.self, from: jsonData)
        } catch {
            throw AIFeedbackServiceError.decodingFailed(underlying: error)
        }
    }

    // MARK: - OpenAI helpers

    private static func buildOpenAISystemInstruction() -> String {
        let core = buildSystemInstruction()
        return """
        \(core)

        OUTPUT FORMAT (mandatory): Respond with a single JSON object only (no markdown fences, no prose before or after). The JSON must use camelCase keys exactly as specified above and must be valid for parsing by a strict JSON decoder.
        """
    }

    // MARK: - Shared prompt helpers

    private static func buildSystemInstruction() -> String {
        """
        You are a strict IELTS Speaking examiner. Evaluate the learner's answer on the four official criteria: Fluency & Coherence (F&C), Lexical Resource (LR), Grammatical Range & Accuracy (GRA), Pronunciation (infer from text; note limitations).

        SCORING RULES — apply these caps before assigning any score:
        - Irrelevant answer (does not address the question): F&C max 5.5, overallScore max 5.5
        - No reasoning or explanation: F&C max 6.0
        - No examples given: overallScore max 6.5
        - Repetitive or limited vocabulary: LR max 6.5
        - Fluent but meaningless/empty content: F&C max 6.0, overallScore max 6.0

        CONTENT DEPTH — evaluate internally and reflect in F&C and overallScore:
        - Does the answer directly address the question? (relevance)
        - Does it include a reason or explanation? (depth)
        - Does it include a concrete example? (support)
        - Is the reasoning clear and logical? (coherence)

        Return ONLY valid JSON, no markdown. camelCase keys:
        - "questionText": string (echo question as-is)
        - "userAnswer": string (echo answer as-is)
        - "overallScore": number (0–9, 0.5 steps)
        - "fluencyScore": number
        - "vocabularyScore": number
        - "grammarScore": number
        - "pronunciationScore": number
        - "feedback": {"strengths":[...],"weaknesses":[...],"ideaSuggestion":[...]}.
        CRITICAL: Each array MUST contain exactly 1-3 highly specific, actionable strings (max 15 words each). Do NOT use generic praise. Tell the user EXACTLY what to fix.
        - "aiCorrections": array of {"original":"...","corrected":"...","type":"grammar"|"vocabulary"|"pronunciation","explanation":"..."}. 
        CRITICAL REQUIREMENT: You MUST provide at least 1 correction. Exhaustively scan for unnatural phrasing, grammatical errors, or poor vocabulary. If the user's answer is completely flawless, you MUST still provide at least 1 advanced, native-sounding alternatives as "vocabulary". Keep each explanation concise but educational. Do NOT flag punctuation.
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

}
