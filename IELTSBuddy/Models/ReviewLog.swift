//
//  ReviewLog.swift
//  IELTSBuddy
//

import Foundation

enum ErrorType: String, Codable, CaseIterable {
    case grammar
    case vocabulary
    case pronunciation
}

struct ReviewLog: Codable, Identifiable, Equatable {
    var id = UUID()
    let original: String
    let corrected: String
    let type: ErrorType
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case id
        case original
        case corrected
        case type
        case explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        original = try container.decode(String.self, forKey: .original)
        corrected = try container.decode(String.self, forKey: .corrected)
        type = try container.decode(ErrorType.self, forKey: .type)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(original, forKey: .original)
        try container.encode(corrected, forKey: .corrected)
        try container.encode(type, forKey: .type)
        try container.encode(explanation, forKey: .explanation)
    }
}
