//
//  ReviewLogViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 5/5/2026.
//

import Foundation

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
    
    // loads all mistakes across all sessions
    func loadMistakes(from sessions: [AIFeedback]) {
        allMistakes = sessions.flatMap { $0.reviewLogs }
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
    
    var mostFrequentType: ErrorType? {
        let counts = [
            ErrorType.grammar: grammarCount,
            ErrorType.vocabulary: vocabularyCount,
            ErrorType.pronunciation: pronunciationCount
        ]
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
