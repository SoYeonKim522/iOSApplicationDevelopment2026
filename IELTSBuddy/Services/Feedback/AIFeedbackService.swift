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
    case missingInputMedia
    case audioPreparationFailed(underlying: Error)

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
        case .missingInputMedia:
            return "No audio or transcript is available to evaluate."
        case .audioPreparationFailed(let underlying):
            return "Failed to prepare audio for evaluation: \(underlying.localizedDescription)"
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

    func fetchFeedback(question: String, userAnswer: String, audioURL: URL?) async throws -> AIFeedback {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedAudioURL = audioURL.flatMap { url in
            FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        let hasAudio = resolvedAudioURL != nil
        let hasTranscript = !trimmedAnswer.isEmpty

        guard hasAudio || hasTranscript else {
            throw AIFeedbackServiceError.missingInputMedia
        }

        if hasAudio, let resolvedAudioURL {
            return try await fetchAudioFeedback(
                question: trimmedQuestion,
                userAnswer: trimmedAnswer,
                audioURL: resolvedAudioURL,
                includesTranscript: hasTranscript
            )
        }

        return try await fetchTranscriptOnlyFeedback(
            question: trimmedQuestion,
            userAnswer: trimmedAnswer
        )
    }

    // MARK: - Audio evaluation (primary path)

    private func fetchAudioFeedback(
        question: String,
        userAnswer: String,
        audioURL: URL,
        includesTranscript: Bool
    ) async throws -> AIFeedback {
        let apiKey = try resolveAPIKey()
        let url = try resolveEndpoint()

        let encodedAudio: (data: String, format: String)
        do {
            encodedAudio = try await OpenAIAudioEncoder.base64EncodedAudio(from: audioURL)
        } catch {
            throw AIFeedbackServiceError.audioPreparationFailed(underlying: error)
        }

        let userText = Self.buildMultimodalUserText(
            question: question,
            userAnswer: userAnswer,
            includesTranscript: includesTranscript
        )

        let body = OpenAIMultimodalChatCompletionRequest(
            model: OpenAIConfig.audioFeedbackModel,
            modalities: ["text"],
            messages: [
                OpenAIMultimodalChatMessage(
                    role: "system",
                    content: .text(Self.buildOpenAISystemInstruction())
                ),
                OpenAIMultimodalChatMessage(
                    role: "user",
                    content: .parts([
                        .text(userText),
                        .inputAudio(data: encodedAudio.data, format: encodedAudio.format),
                    ])
                ),
            ],
            responseFormat: nil,
            temperature: 0.3
        )

        let data = try await performRequest(url: url, apiKey: apiKey, body: body)
        return try decodeFeedback(from: data)
    }

    // MARK: - Transcript-only fallback

    private func fetchTranscriptOnlyFeedback(question: String, userAnswer: String) async throws -> AIFeedback {
        let apiKey = try resolveAPIKey()
        let url = try resolveEndpoint()

        let body = OpenAIChatCompletionRequest(
            model: OpenAIConfig.feedbackModel,
            messages: [
                OpenAIChatMessage(role: "system", content: Self.buildOpenAISystemInstruction()),
                OpenAIChatMessage(role: "user", content: Self.buildUserContent(question: question, userAnswer: userAnswer)),
            ],
            responseFormat: .init(type: "json_object")
        )

        let data = try await performRequest(url: url, apiKey: apiKey, body: body)
        return try decodeFeedback(from: data)
    }

    // MARK: - Networking

    private func resolveAPIKey() throws -> String {
        do {
            return try apiKeyProvider()
        } catch {
            throw AIFeedbackServiceError.missingAPIKey
        }
    }

    private func resolveEndpoint() throws -> URL {
        guard let url = URL(string: OpenAIConfig.endpoint) else {
            throw AIFeedbackServiceError.invalidURL
        }
        return url
    }

    private func performRequest<Body: Encodable>(url: URL, apiKey: String, body: Body) async throws -> Data {
        let bodyData: Data
        do {
            bodyData = try JSONEncoder().encode(body)
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

        return data
    }

    private func decodeFeedback(from data: Data) throws -> AIFeedback {
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

    // MARK: - Prompt helpers

    private static func buildOpenAISystemInstruction() -> String {
        let core = buildSystemInstruction()
        return """
        \(core)

        OUTPUT FORMAT (mandatory): Respond with a single JSON object only (no markdown fences, no prose before or after). The JSON must use camelCase keys exactly as specified above and must be valid for parsing by a strict JSON decoder.
        """
    }

    private static func buildSystemInstruction() -> String {
        """
        You are a strict, certified IELTS Speaking examiner with over 15 years of experience. You evaluate exactly like real British Council, IDP, and Cambridge examiners using the official IELTS Speaking Band Descriptors.
        Assume this is an IELTS Speaking Part 1 response.

        You are given both the audio recording (primary source) and the STT transcript (supporting only).

        [AUDIO-FIRST POLICY - STRICT]
        - Audio is the absolute primary source for Fluency & Coherence, and Pronunciation.
        - Evaluate real spoken delivery: natural rhythm, intonation, stress patterns, connected speech, chunking, hesitations, and self-corrections.

        OFFICIAL IELTS CRITERIA:
        1. Fluency & Coherence (F&C) - Natural flow, minimal hesitation, self-correction, AND logical development with appropriate relevance and extension for Part 1.
        2. Lexical Resource (LR)
        3. Grammatical Range & Accuracy (GRA)
        4. Pronunciation - Intelligibility, word stress, sentence stress, intonation, rhythm, linking, and individual sounds.

        PART 1 SPECIFIC GUIDELINES:
        - Part 1 answers are typically 15-30 seconds (2-4 sentences). Do not expect long development.
        - Focus feedback on natural extension, reasons, and personal details rather than specific examples.

        PRONUNCIATION EVALUATION (Very Important):
        - Pay close attention to word stress (e.g. fulFILling NOT FULfilling, reWARding NOT REWarding).
        - Check intonation, rhythm, chunking, and individual sounds (work vs walk, etc.).
        - If word stress or intonation is noticeably wrong, lower the Pronunciation score and mention it specifically in weaknesses or aiCorrections.

        IMPORTANT STABILITY & CORRECTION RULES:
        - Vocabulary and Grammar scores must stay consistent for the same content unless there are clear spoken errors in the final utterance.
        - Self-rephrasing, false starts, mid-sentence corrections, and hesitations are Fluency & Coherence issues — NEVER treat them as grammar or vocabulary errors in aiCorrections.
        - Do NOT lower Vocab or Grammar due to hesitations, accent, or delivery issues. Those affect only Fluency & Coherence or Pronunciation.
        - Pronunciation score should remain fair even with a noticeable Korean accent if intelligibility is maintained.

        SCORING RULES (Apply these caps first):
        - Completely irrelevant or off-topic: F&C ≤ 5.5, Overall ≤ 5.5
        - Very short or no extension/reasons: F&C ≤ 6.0, Overall ≤ 6.0
        - Very repetitive or basic vocabulary: LR ≤ 6.5

        Return ONLY valid JSON. No markdown, no extra text. Use camelCase keys.

        {
          "questionText": string,
          "userAnswer": string,
          "overallScore": number,
          "fluencyScore": number,
          "vocabularyScore": number,
          "grammarScore": number,
          "pronunciationScore": number,
          
          "feedback": {
            "strengths": [array of 1-3 highly specific, actionable strings (max 15 words each)],
            "weaknesses": [array of 1-3 highly specific, actionable strings (max 15 words each)],
            "ideaSuggestion": [array of 1-3 concrete improvement ideas suitable for Part 1 (max 15 words each)]
          },
          
          "aiCorrections": [
            {
              "original": "...",
              "corrected": "...",
              "type": "grammar" | "vocabulary" | "pronunciation",
              "explanation": "..."
            }
          ]
        }

        CRITICAL RULES:
        - In aiCorrections, ONLY correct real grammar, vocabulary, or pronunciation errors in the final spoken content. 
        - NEVER flag self-rephrasing, false starts, or mid-sentence corrections as grammar or vocabulary mistakes.
        - Always provide at least 1 correction when there are real issues. If almost perfect, give one advanced alternative as vocabulary.
        - Idea suggestions should focus on adding reasons, personal details, or natural extension for Part 1.
        - Explanations must be concise, educational, and examiner-like.
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

    private static func buildMultimodalUserText(
        question: String,
        userAnswer: String,
        includesTranscript: Bool
    ) -> String {
        if includesTranscript {
            return """
            QUESTION: \(question)
            TRANSCRIPT: \(userAnswer)
            Evaluate the user's spoken response based on the audio, using the transcript as supplementary context.
            """
        }

        return """
        QUESTION: \(question)
        Evaluate the user's spoken response based on the audio.
        """
    }
}
