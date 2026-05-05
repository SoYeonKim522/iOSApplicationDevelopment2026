//
//  FeedbackResultView.swift
//  IELTSBuddy
//

import AVFoundation
import SwiftUI

struct FeedbackResultView: View {
    let questionText: String
    let transcript: String
    let audioFileURL: URL?

    @State private var feedbackResult: AIFeedback?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    private let aiFeedbackService = AIFeedbackService()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                Spacer()
                ProgressView("Analyzing your answer...")
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if let feedbackResult {
                HStack {
                    Text("Transcript")
                        .font(.headline)
                    Spacer()
                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(audioFileURL == nil ? .secondary : .accentColor)
                            .padding(16)
                            .contentShape(Rectangle())
                    }
                    .disabled(audioFileURL == nil)
                    .accessibilityLabel(isPlaying ? "Stop playback" : "Play recording")
                }
                ScrollView {
                    Text(transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)

                Text("Scores")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Overall: %.1f", feedbackResult.overallScore))
                    Text(String(format: "Fluency: %.1f", feedbackResult.fluencyScore))
                    Text(String(format: "Vocabulary: %.1f", feedbackResult.vocabularyScore))
                    Text(String(format: "Grammar: %.1f", feedbackResult.grammarScore))
                    Text(String(format: "Pronunciation: %.1f", feedbackResult.pronunciationScore))
                }

                Text("Review Logs")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(feedbackResult.reviewLogs) { log in
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Original: \(log.original)")
                                Text("Corrected: \(log.corrected)")
                                Text("Explanation: \(log.explanation)")
                            }
                            .font(.footnote)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Feedback")
        .task {
            await loadFeedback()
        }
        .onDisappear {
            audioPlayer?.stop()
            isPlaying = false
        }
    }

    @MainActor
    private func loadFeedback() async {
        isLoading = true
        errorMessage = nil

        do {
            feedbackResult = try await aiFeedbackService.fetchFeedback(
                question: questionText,
                userAnswer: transcript
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func togglePlayback() {
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
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }
}

#Preview {
    FeedbackResultView(
        questionText: "Describe your hometown.",
        transcript: "My hometown is very beautiful.",
        audioFileURL: nil
    )
}
