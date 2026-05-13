//
//  HistoryViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 5/5/2026.
//

import Foundation
import Combine
import SwiftUI

// stores and manages all completed practice sessions
class HistoryViewModel: ObservableObject {
    
    @Published var sessions: [AIFeedback] = []
    @Published var selectedSession: AIFeedback? = nil
    @Published var errorMessage: String? = nil
    private let storageKey = "savedSessions"
    
    // all persistence goes through here to keep storage logic in one place
    private func persistSessions() {
        do {
            let encoded = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("Failed to save sessions: \(error)")
            errorMessage = "Something went wrong. Please try again."
        }
    }
    
    func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            sessions = try JSONDecoder().decode([AIFeedback].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
            errorMessage = "Could not load your history. Please try again."
        }
    }
    
    // saves a new session after practice
    func saveSession(_ feedback: AIFeedback) {
        loadSessions()
        sessions.append(feedback)
        persistSessions()
    }
    
    // called when user taps a session in the list
    func selectSession(_ feedback: AIFeedback) {
        selectedSession = feedback
    }
    
    // delete a session
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persistSessions()
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    func sessions(above score: Double) -> [AIFeedback] {
        sessions.filter { $0.overallScore >= score }
    }
}
