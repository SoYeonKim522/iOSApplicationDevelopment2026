//
//  BookmarkViewModel.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 12/5/2026.
//

import Foundation
import Combine

// manages saving and loading bookmarked mistakes across sessions
class BookmarkViewModel: ObservableObject {
    
    private let storageKey = StorageKeys.bookmarkedMistakes
    private let storage: StorageService
    
    @Published var bookmarks: [BookmarkedMistake] = []
    @Published var errorMessage: String? = nil
    
    init(storage: StorageService = UserDefaultsStorageService()) {
            self.storage = storage
        }
    
    func loadBookmarks() {
        do {
            bookmarks = try storage.load([BookmarkedMistake].self, forKey: storageKey) ?? []
                    } catch {
            print("Failed to load bookmarks: \(error)")
            errorMessage = "Could not load your saved mistakes. Please try again."
        }
    }
    
    func addBookmark(from log: ReviewLog, sessionId: UUID) {
        // prevent duplicates from different screens
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
    // all saves go through here to keep persistence logic in one place
    private func persist() {
        do {
            try storage.save(bookmarks, forKey: storageKey)
        } catch {
            print("Failed to save bookmarks: \(error)")
            errorMessage = "Could not save your bookmark. Please try again."
        }
    }
}
