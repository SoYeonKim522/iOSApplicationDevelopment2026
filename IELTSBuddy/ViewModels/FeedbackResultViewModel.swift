//
//  FeedbackResultViewModel.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 9/5/2026.
//

import AVFoundation
import Foundation
import SwiftUI
import Combine

@MainActor
final class FeedbackResultViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    let questionText: String
    let transcript: String
    let audioFileURL: URL?

    @Published private(set) var feedbackResult: AIFeedback?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var isPlaying = false
    @Published var savedLogIDs: Set<UUID> = []
    @Published var bookmarkViewModel: BookmarkViewModel

    private let aiFeedbackService: any AIFeedbackProviding
    private let historyViewModel: HistoryViewModel
    private var audioPlayer: AVAudioPlayer?

    init(
        questionText: String,
        transcript: String,
        audioFileURL: URL?,
        aiFeedbackService: (any AIFeedbackProviding)? = nil,
        historyViewModel: HistoryViewModel? = nil,
    ){
        self.bookmarkViewModel = BookmarkViewModel()
        self.questionText = questionText
        self.transcript = transcript
        self.audioFileURL = audioFileURL
        
        if AppConfig.useMockAPI {
                self.aiFeedbackService = MockAIFeedbackService()
            } else {
                self.aiFeedbackService = aiFeedbackService ?? AIFeedbackService()
            }
        
        self.historyViewModel = historyViewModel ?? HistoryViewModel()
    }

    func loadFeedback() async {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            feedbackResult = AIFeedback.mock
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await aiFeedbackService.fetchFeedback(
                question: questionText,
                userAnswer: transcript
            )
            feedbackResult = result
            historyViewModel.saveSession(result)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func togglePlayback() {
        guard let audioFileURL else { return }

        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: audioFileURL)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            
            audioPlayer = player
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func toggleSaved(_ log: ReviewLog, sessionId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if savedLogIDs.contains(log.id) {
                savedLogIDs.remove(log.id)
                bookmarkViewModel.removeBookmark(id: log.id)
            } else {
                savedLogIDs.insert(log.id)
                bookmarkViewModel.addBookmark(from: log, sessionId: sessionId)
            }
        }
    }

    func isBookmarked(_ id: UUID) -> Bool {
        bookmarkViewModel.isBookmarked(id)
    }

    func onDisappear() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    //delegate function
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
