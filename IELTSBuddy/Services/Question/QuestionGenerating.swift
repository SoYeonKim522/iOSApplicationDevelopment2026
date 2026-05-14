//
//  QuestionGenerating.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 10/5/2026.
//

import Foundation

protocol QuestionGenerating {
    func generateQuestion(topic: TopicCategory, part: PartType) async throws -> PracticeQuestion
}
