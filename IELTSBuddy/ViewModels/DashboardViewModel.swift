//
//  DashboardViewModel.swift
//  IELTSBuddy
//
//  Dashboard: session stats and recommended topic chips. Question loading lives in RecordingViewModel.
//

import Combine
import Foundation

final class DashboardViewModel: ObservableObject {

    static let practiceSessionsStorageKey = "savedSessions"

    @Published private(set) var sessionCount: Int = 0
    @Published private(set) var practicesToday: Int = 0
    @Published private(set) var weeklyPracticeCount: Int = 0
    @Published var recommendedTopicItems: [RecommendedTopicItem] = []

    init() {
        refreshStats()
        refreshRecommendedTopics()
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
            sessionCount = 0
            practicesToday = 0
            weeklyPracticeCount = 0
        }
    }

    func refreshRecommendedTopics() {
        let picks = TopicCategory.allCases.shuffled().prefix(3)
        recommendedTopicItems = picks.map { topic in
            RecommendedTopicItem(id: UUID(), topicCategory: topic, part: .part1)
        }
    }
}
