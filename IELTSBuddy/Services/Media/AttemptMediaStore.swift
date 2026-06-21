//
//  AttemptMediaStore.swift
//  IELTSBuddy
//

import Foundation

/// Resolves question, transcript, and audio URL for a speaking attempt by shared `attemptId`.
@MainActor
final class AttemptMediaStore {
    static let shared = AttemptMediaStore()

    private var attempts: [UUID: SpeakingAttempt] = [:]

    private init() {}

    func register(_ attempt: SpeakingAttempt) {
        attempts[attempt.id] = attempt
    }

    func attempt(for id: UUID) -> SpeakingAttempt? {
        attempts[id]
    }

    func remove(id: UUID) {
        attempts.removeValue(forKey: id)
    }
}
