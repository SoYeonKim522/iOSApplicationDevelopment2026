//
//  HistoryViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 5/5/2026.
//

import Foundation
import Combine

// stores and manages all completed practice sessions
class HistoryViewModel: ObservableObject {
    
    @Published var sessions: [AIFeedback] = []
    @Published var errorMessage: String? = nil
    
    private let storageKey = StorageKeys.savedSessions
    private let storage: StorageService
    
    init(storage: StorageService = UserDefaultsStorageService()) {
        self.storage = storage
    }
    
    // all persistence goes through here to keep storage logic in one place
    private func persistSessions() {
        do {
            try storage.save(sessions, forKey: storageKey)
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
    
    func loadSessions() {
        do {
            sessions = try storage.load([AIFeedback].self, forKey: storageKey) ?? []
        } catch {
            errorMessage = "Could not load your history. Please try again."
        }
    }
    
    // saves a new session after practice
    func saveSession(_ feedback: AIFeedback) {
        loadSessions()
        sessions.append(feedback)
        persistSessions()
    }
    
    func deleteSession(_ session: AIFeedback) {
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }
    
    var sortedSessions: [AIFeedback] {
        sessions.sorted { $0.date > $1.date }
    }
}
