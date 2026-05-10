//
//  MockQuestionGeneratorService.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 10/5/2026.
//

import Foundation


final class MockQuestionGeneratorService: QuestionGenerating {
    func generateQuestion(topic: String, part: String) async throws -> PracticeQuestion {
        PracticeQuestion(
            text: "Mock: \(topic) / \(part). Proceed to record",
            part: PartType(rawValue: part) ?? .part1,
            topicCategory: TopicCategory(rawValue: topic) ?? .work,
            estimatedDuration: 60
        )
    }
}
