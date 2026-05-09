//
//  DashboardViewModel.swift
//  IELTSBuddy
//
//  Dashboard: session stats, upcoming question chips, optional Gemini fetch.
//

import Combine
import Foundation
import SwiftUI

struct UpcomingQuestionItem: Identifiable, Equatable {
    let id: UUID
    let questionNumber: Int
    let partLabel: String
    let topicTitle: String
}

final class DashboardViewModel: ObservableObject {

    static let practiceSessionsStorageKey = "savedSessions"

    @Published private(set) var sessionCount: Int = 0
    @Published private(set) var practicesToday: Int = 0
    @Published private(set) var weeklyPracticeCount: Int = 0
    @Published var upcomingItems: [UpcomingQuestionItem] = []

    @Published var selectedTopic: TopicCategory = .work
    @Published var selectedPart: PartType = .part1
    @Published var currentQuestion: PracticeQuestion?
    @Published var isLoadingQuestion: Bool = false
    @Published var questionError: String?

    private let questionGenerator: QuestionGeneratorService

    init(questionGenerator: QuestionGeneratorService = QuestionGeneratorService()) {
        self.questionGenerator = questionGenerator
        refreshStats()
        refreshUpcomingQuestions()
    }

    // Reloads counts from the same store as HistoryViewModel.
    func refreshStats() {
        let key = Self.practiceSessionsStorageKey
        let cal = Calendar.current
        let now = Date()

        guard let data = UserDefaults.standard.data(forKey: key) else {
            sessionCount = 0
            practicesToday = 0
            weeklyPracticeCount = 0
            return
        }

        do {
            let sessions = try JSONDecoder().decode([AIFeedback].self, from: data)
            sessionCount = sessions.count
            practicesToday = sessions.filter { cal.isDateInToday($0.date) }.count
            weeklyPracticeCount = sessions.filter {
                cal.isDate($0.date, equalTo: now, toGranularity: .weekOfYear)
            }.count
        } catch {
            print("Failed to decode practice sessions for dashboard: \(error)")
            sessionCount = 0
            practicesToday = 0
            weeklyPracticeCount = 0
        }
    }

    func refreshUpcomingQuestions() {
        let picks = TopicCategory.allCases.shuffled().prefix(3)
        upcomingItems = picks.enumerated().map { index, topic in
            UpcomingQuestionItem(
                id: UUID(),
                questionNumber: index + 1,
                partLabel: "Part 1",
                topicTitle: topicTitle(topic)
            )
        }
    }

    private func topicTitle(_ topic: TopicCategory) -> String {
        topic.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

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
