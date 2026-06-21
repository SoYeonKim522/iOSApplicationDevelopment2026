//
//  SpeakingAttempt.swift
//  IELTSBuddy
//

import Foundation

/// A single speaking practice attempt tying question, transcript, and recorded audio together.
struct SpeakingAttempt: Identifiable, Hashable {
    let id: UUID
    let question: String
    let transcript: String
    let audioURL: URL?

    init(
        id: UUID = UUID(),
        question: String,
        transcript: String,
        audioURL: URL?
    ) {
        self.id = id
        self.question = question
        self.transcript = transcript
        self.audioURL = audioURL
    }
}
