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
    let mistake: String
    let dateAdded: Date
    let sessionId: UUID

    init(
        id: UUID = UUID(),
        mistake: String,
        dateAdded: Date = Date(),
        sessionId: UUID
    ) {
        self.id = id
        self.mistake = mistake.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dateAdded = dateAdded
        self.sessionId = sessionId
    }
}
