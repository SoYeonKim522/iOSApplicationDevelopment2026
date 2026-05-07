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
    @State private var playbackMonitor: Timer?
    @State private var savedLogIDs: Set<UUID> = []

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

                Text("Key Corrections")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(feedbackResult.reviewLogs) { log in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    Text(log.type.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        toggleSaved(log.id)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: savedLogIDs.contains(log.id) ? "checkmark.circle.fill" : "plus.circle")
                                                .font(.system(size: 18, weight: .semibold))
                                            if savedLogIDs.contains(log.id) {
                                                Text("Saved")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .foregroundStyle(savedLogIDs.contains(log.id) ? Color.green : Color.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(savedLogIDs.contains(log.id) ? "Saved mistake" : "Save mistake")
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Original")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(log.original)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Corrected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(log.corrected)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Explanation")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(log.explanation)
                                }
                            }
                            .font(.footnote)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.95, green: 0.92, blue: 0.88))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
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
            stopPlaybackMonitoring()
            audioPlayer?.stop()
            isPlaying = false
        }
        .safeAreaInset(edge: .bottom) {

            if isLoading {
                EmptyView()
            } else if errorMessage != nil {

                // error -> Retry button only
                Button {
                    Task {
                        await loadFeedback()
                    }
                } label: {
                    Text("Retry")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
                .padding()
                .background(.ultraThinMaterial)

            } else if feedbackResult != nil {

                // success -> Retry + Next Question
                HStack(spacing: 12) {

                    Button {
                        Task {
                            await loadFeedback()
                        }
                    } label: {
                        Text("Retry")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )

                    Button {
                    } label: {
                        Text("Next Question")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                    }
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
    }

    @MainActor
    private func loadFeedback() async {
        // Preview case -> skip api call
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                self.feedbackResult = AIFeedback.mock
                self.isLoading = false
                return
            }
        // ends
        
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
            stopPlaybackMonitoring()
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
            startPlaybackMonitoring()
        } catch {
            stopPlaybackMonitoring()
            isPlaying = false
        }
    }

    private func startPlaybackMonitoring() {
        stopPlaybackMonitoring()
        playbackMonitor = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            guard let audioPlayer else {
                stopPlaybackMonitoring()
                isPlaying = false
                return
            }

            if !audioPlayer.isPlaying {
                stopPlaybackMonitoring()
                isPlaying = false
            }
        }
    }

    private func stopPlaybackMonitoring() {
        playbackMonitor?.invalidate()
        playbackMonitor = nil
    }

    private func toggleSaved(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if savedLogIDs.contains(id) {
                savedLogIDs.remove(id)
            } else {
                savedLogIDs.insert(id)
            }
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
