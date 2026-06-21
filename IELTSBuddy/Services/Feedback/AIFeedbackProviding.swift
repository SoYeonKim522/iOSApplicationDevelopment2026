//
//  AIFeedbackProviding.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 10/5/2026.
//

import Foundation

protocol AIFeedbackProviding {
    func fetchFeedback(question: String, userAnswer: String, audioURL: URL?) async throws -> AIFeedback
}
