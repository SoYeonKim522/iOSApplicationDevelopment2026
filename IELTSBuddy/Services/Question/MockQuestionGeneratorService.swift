//
//  MockQuestionGeneratorService.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 10/5/2026.
//

import Foundation

final class MockQuestionGeneratorService: QuestionGenerating {
    func generateQuestion(topic: TopicCategory, part: PartType) async throws -> PracticeQuestion {
        PracticeQuestion(
            text: "Mock: \(topic.rawValue) / \(part.rawValue). Proceed to record",
            part: part,
            topicCategory: topic,
            estimatedDuration: 60
        )
    }
}
