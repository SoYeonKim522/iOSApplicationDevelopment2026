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
    let topicCategory: TopicCategory
    let part: PartType

    var topicTitle: String {
        topicCategory.displayTitleForRecommendation
    }

    var partLabel: String {
        part.shortLabelForRecommendation
    }

    var emoji: String {
        topicCategory.recommendationEmoji
    }
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
        upcomingItems = picks.map { topic in
            UpcomingQuestionItem(id: UUID(), topicCategory: topic, part: .part1)
        }
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
