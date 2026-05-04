//
//  PracticeQuestion.swift
//  IELTSBuddy
//

import Foundation

enum PartType: String, Codable, CaseIterable {
    case part1
    case part2
    case part3
}

enum TopicCategory: String, Codable, CaseIterable {
    case work
    case study
    case hometown
    case hobbies
    case environment
    case technology
    case health
    case travel
    case family
    case food
    case culture
    case sports
    case education
    case media
    case society
    case business
    case accommodation
    case weather
    case friends
    case shopping
    case music
    case reading
}

struct PracticeQuestion: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let part: PartType
    let topicCategory: TopicCategory
    let estimatedDuration: Int

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case part
        case topicCategory
        case estimatedDuration
    }

    init(
        id: UUID = UUID(),
        text: String,
        part: PartType,
        topicCategory: TopicCategory,
        estimatedDuration: Int
    ) {
        self.id = id
        self.text = text
        self.part = part
        self.topicCategory = topicCategory
        self.estimatedDuration = estimatedDuration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        text = try container.decode(String.self, forKey: .text)
        part = try container.decode(PartType.self, forKey: .part)
        topicCategory = try container.decode(TopicCategory.self, forKey: .topicCategory)
        estimatedDuration = try container.decode(Int.self, forKey: .estimatedDuration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(part, forKey: .part)
        try container.encode(topicCategory, forKey: .topicCategory)
        try container.encode(estimatedDuration, forKey: .estimatedDuration)
    }
}
