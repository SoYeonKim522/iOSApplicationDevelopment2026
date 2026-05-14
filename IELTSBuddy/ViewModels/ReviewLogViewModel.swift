//
//  ReviewLogViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 5/5/2026.
//

import Foundation
import SwiftUI
import Combine

// handles filtering and aggregating mistakes across all practice sessions
class ReviewLogViewModel: ObservableObject {
    
    @Published var allMistakes: [ReviewLog] = []
    @Published var filteredMistakes: [ReviewLog] = []
    @Published var selectedFilter: ErrorType? = nil
    
    var totalMistakes: Int {
        filteredMistakes.count
    }
    
    var grammarCount: Int {
        allMistakes.filter { $0.type == .grammar }.count
    }
    
    var vocabularyCount: Int {
        allMistakes.filter { $0.type == .vocabulary }.count
    }
    
    var pronunciationCount: Int {
        allMistakes.filter { $0.type == .pronunciation }.count
    }
    
    func loadMistakes(from sessions: [AIFeedback]) {
        // flatMap pulls mistakes out of every session into one list
        allMistakes = sessions.flatMap { $0.aiCorrections }
        applyFilter()
    }
    
    // filter by grammar, vocabulary or pronunciation
    func filterBy(_ type: ErrorType?) {
        selectedFilter = type
        applyFilter()
    }
    
    private func applyFilter() {
        if let filter = selectedFilter {
            filteredMistakes = allMistakes.filter { $0.type == filter }
        } else {
            filteredMistakes = allMistakes
        }
    }
    
    func clearAll() {
        allMistakes = []
        filteredMistakes = []
    }
    
    func count(for type: ErrorType) -> Int {
        allMistakes.filter { $0.type == type }.count
    }
    
}
