//
//  OpenAIShared.swift
//  IELTSBuddy
//

import Foundation

// MARK: - Request DTOs

struct OpenAIChatCompletionRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let responseFormat: OpenAIResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

struct OpenAIChatMessage: Encodable {
    let role: String
    let content: String
}

struct OpenAIResponseFormat: Encodable {
    let type: String
}

// MARK: - Multimodal request DTOs (gpt-4o-audio-preview)

struct OpenAIMultimodalChatCompletionRequest: Encodable {
    let model: String
    let modalities: [String]
    let messages: [OpenAIMultimodalChatMessage]
    let responseFormat: OpenAIResponseFormat?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case model
        case modalities
        case messages
        case responseFormat = "response_format"
        case temperature
    }
}

struct OpenAIMultimodalChatMessage: Encodable {
    let role: String
    let content: OpenAIMultimodalMessageContent
}

enum OpenAIMultimodalMessageContent: Encodable {
    case text(String)
    case parts([OpenAIMultimodalContentPart])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .parts(let parts):
            try container.encode(parts)
        }
    }
}

struct OpenAIMultimodalContentPart: Encodable {
    let type: String
    let text: String?
    let inputAudio: OpenAIInputAudioPayload?

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case inputAudio = "input_audio"
    }

    static func text(_ value: String) -> Self {
        Self(type: "text", text: value, inputAudio: nil)
    }

    static func inputAudio(data: String, format: String) -> Self {
        Self(type: "input_audio", text: nil, inputAudio: .init(data: data, format: format))
    }
}

struct OpenAIInputAudioPayload: Encodable {
    let data: String
    let format: String
}

// MARK: - Response DTOs

struct OpenAIChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message?
    }
    let choices: [Choice]?
}

// MARK: - Helpers

enum OpenAIHelpers {
    /// Removes a leading/trailing ```json ... ``` wrapper if the model adds one despite instructions.
    static func stripMarkdownCodeFence(from content: String) -> String {
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

    static func extractOpenAIErrorMessage(from data: Data) -> String? {
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
}
