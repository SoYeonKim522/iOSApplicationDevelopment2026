//
//  RecommendedTopicItem.swift
//  IELTSBuddy
//
//  Dashboard “recommended topics” chip row — topic/part pair for navigation shortcuts.
//

import Foundation

struct RecommendedTopicItem: Identifiable, Equatable {
    let id: UUID
    let topicCategory: TopicCategory
    let part: PartType

    var topicTitle: String {
        topicCategory.displayTitleForRecommendation
    }

    var partLabel: String {
        part.shortLabelForRecommendation
    }

    var emoji: String {
        topicCategory.recommendationEmoji
    }
}
