//
//  BookmarkedMistake.swift
//  IELTSBuddy
//
//  A mistake the learner chose to save for later review.
//

import Foundation

struct BookmarkedMistake: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    // Free-form text copied from the feedback.
    let original: String
    let corrected: String
    let type: ErrorType
    let explanation: String
    let dateAdded: Date
    let sessionId: UUID

    init(
        id: UUID = UUID(),
        original: String,
        corrected: String,
        type: ErrorType,
        explanation: String,
        dateAdded: Date = Date(),
        sessionId: UUID
    ) {
        self.id = id
        self.original = original
        self.corrected = corrected
        self.type = type
        self.explanation = explanation
        self.dateAdded = dateAdded
        self.sessionId = sessionId
    }
}
