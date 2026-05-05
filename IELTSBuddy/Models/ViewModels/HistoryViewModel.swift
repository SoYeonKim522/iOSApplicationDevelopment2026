//
//  HistoryViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 5/5/2026.
//

import Foundation

class HistoryViewModel: ObservableObject {
    
    @Published var sessions: [AIFeedback] = []
    @Published var selectedSession: AIFeedback? = nil
    @Published var errorMessage: String? = nil
    private let storageKey = "savedSessions"
  
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
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "savedSessions"),
           let decoded = try? decoder.decode([AIFeedback].self, from: data) {
            sessions = decoded
        }
    }
    
    // saves a new session after practice
    func saveSession(_ feedback: AIFeedback) {
        sessions.append(feedback)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }
    
    // called when user taps a session in the list
    func selectSession(_ feedback: AIFeedback) {
        selectedSession = feedback
    }
    
    // delete a session
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedSessions")
        }
    }
    
    var totalSessions: Int {
            sessions.count
        }
    
    func sessions(above score: Double) -> [AIFeedback] {
            sessions.filter { $0.overallScore >= score }
        }
}
