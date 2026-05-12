//
//  BookmarkViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 12/5/2026.
//

import Foundation
import Combine

class BookmarkViewModel: ObservableObject {
    
    private let storageKey = "bookmarkedMistakes"
    
    @Published var bookmarks: [BookmarkedMistake] = []
    @Published var errorMessage: String? = nil
    
    func loadBookmarks() {
        do {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
            bookmarks = try JSONDecoder().decode([BookmarkedMistake].self, from: data)
        } catch {
            print("Failed to load bookmarks: \(error)")
            errorMessage = "Could not load bookmarks."
        }
    }
    
    func addBookmark(from log: ReviewLog, sessionId: UUID) {
        // don't add duplicates
        guard !bookmarks.contains(where: { $0.id == log.id }) else { return }
        
        let bookmark = BookmarkedMistake(
            id: log.id,
            original: log.original,
            corrected: log.corrected,
            type: log.type,
            explanation: log.explanation,
            sessionId: sessionId
        )
        bookmarks.append(bookmark)
        persist()
    }
    
    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        persist()
    }
    
    func isBookmarked(_ id: UUID) -> Bool {
        bookmarks.contains { $0.id == id }
    }
    
    private func persist() {
        do {
            let encoded = try JSONEncoder().encode(bookmarks)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("Failed to save bookmarks: \(error)")
            errorMessage = "Could not save bookmark."
        }
    }
}
