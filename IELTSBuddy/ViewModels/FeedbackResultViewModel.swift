//
//  FeedbackResultViewModel.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 9/5/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FeedbackResultViewModel: ObservableObject {
    let attempt: SpeakingAttempt

    var questionText: String { attempt.question }
    var transcript: String { attempt.transcript }
    var audioFileURL: URL? { attempt.audioURL }

    @Published private(set) var feedbackResult: AIFeedback?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var playbackError: String?
    
    @Published var bookmarkViewModel: BookmarkViewModel
    
    private let aiFeedbackService: any AIFeedbackProviding
    private let historyViewModel: HistoryViewModel
    private let audioPlaybackManager: AudioPlaybackManaging

    init(
        attempt: SpeakingAttempt,
        services: AppServices,
        historyViewModel: HistoryViewModel? = nil,
        audioPlaybackManager: AudioPlaybackManaging? = nil
    ){
        self.bookmarkViewModel = BookmarkViewModel.shared
        self.attempt = attempt
        self.audioPlaybackManager = audioPlaybackManager ?? AVAudioPlaybackManager()
        self.aiFeedbackService = services.aiFeedback
        self.historyViewModel = historyViewModel ?? HistoryViewModel()
        self.audioPlaybackManager.onFinished = { [weak self] in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }
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
                question: attempt.question,
                userAnswer: attempt.transcript,
                audioURL: attempt.audioURL
            )
            print(result)
            print("____________")
            dump(result)
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
            audioPlaybackManager.stop()
            isPlaying = false
            return
        }

        do {
            try audioPlaybackManager.play(url: audioFileURL)
            isPlaying = true
            playbackError = nil
        } catch {
            isPlaying = false
            playbackError = "Unable to play recording."
        }
    }

    func toggleSaved(_ log: ReviewLog, sessionId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if bookmarkViewModel.isBookmarked(log.id) {
                        bookmarkViewModel.removeBookmark(id: log.id)
                    } else {
                        bookmarkViewModel.addBookmark(from: log, sessionId: sessionId)
                    }
        }
    }

    func onDisappear() {
        audioPlaybackManager.stop()
        isPlaying = false
    }

}
