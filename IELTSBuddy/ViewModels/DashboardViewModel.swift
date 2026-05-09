//
//  DashboardViewModel.swift
//  IELTSBuddy
//
//  Dashboard: practice session count + loading a question via Gemini
//
//

import Combine
import Foundation
import SwiftUI

final class DashboardViewModel: ObservableObject {

    // Must match HistoryViewModel’s storage key for persisted AIFeedback sessions.
    static let practiceSessionsStorageKey = "savedSessions"

    @Published var sessionCount: Int = 0
    @Published var selectedTopic: TopicCategory = .work
    @Published var selectedPart: PartType = .part1
    @Published var currentQuestion: PracticeQuestion?
    @Published var isLoadingQuestion: Bool = false
    @Published var questionError: String?

    private let questionGenerator: QuestionGeneratorService

    init(questionGenerator: QuestionGeneratorService = QuestionGeneratorService()) {
        self.questionGenerator = questionGenerator
        refreshSessionCount()
    }

    // Reloads session count from the same store HistoryViewModel uses.
    func refreshSessionCount() {
        let key = Self.practiceSessionsStorageKey
        guard let data = UserDefaults.standard.data(forKey: key) else {
            sessionCount = 0
            return
        }
        do {
            let sessions = try JSONDecoder().decode([AIFeedback].self, from: data)
            sessionCount = sessions.count
        } catch {
            print("Failed to decode practice sessions for dashboard: \(error)")
            sessionCount = 0
        }
    }

    // Fetches one question for the current topic
    @MainActor
    func loadQuestion() async {
        isLoadingQuestion = true
        questionError = nil
        defer { isLoadingQuestion = false }

        do {
            currentQuestion = try await questionGenerator.generateQuestion(
                topic: selectedTopic.rawValue,
                part: selectedPart.rawValue
            )
        } catch {
            questionError = error.localizedDescription
        }
    }
}
