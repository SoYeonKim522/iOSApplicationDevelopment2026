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

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackMonitor: Timer?
    @State private var savedLogIDs: Set<UUID> = []
    
    @StateObject private var viewModel: FeedbackResultViewModel

        init(
            questionText: String,
            transcript: String,
            audioFileURL: URL?
        ) {
            self.questionText = questionText
            self.transcript = transcript
            self.audioFileURL = audioFileURL

            _viewModel = StateObject(
                wrappedValue: FeedbackResultViewModel(
                    questionText: questionText,
                    transcript: transcript,
                    audioFileURL: audioFileURL
                )
            )
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Analyzing your answer...")
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if let feedbackResult = viewModel.feedbackResult {
                HStack {
                    Text("Transcript")
                        .font(.headline)
                    Spacer()
                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
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
                                        viewModel.toggleSaved(log.id)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: viewModel.savedLogIDs.contains(log.id) ? "checkmark.circle.fill" : "plus.circle")
                                                .font(.system(size: 18, weight: .semibold))
                                            if viewModel.savedLogIDs.contains(log.id) {
                                                Text("Saved")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .foregroundStyle(viewModel.savedLogIDs.contains(log.id) ? Color.green : Color.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(viewModel.savedLogIDs.contains(log.id) ? "Saved mistake" : "Save mistake")
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
            await viewModel.loadFeedback()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .safeAreaInset(edge: .bottom) {

            if viewModel.isLoading {
                EmptyView()
            } else if viewModel.errorMessage != nil {

                // error -> Retry button only
                Button {
                    Task {
                        await viewModel.loadFeedback()
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

            } else if viewModel.feedbackResult != nil {

                // success -> Retry + Next Question
                HStack(spacing: 12) {

                    Button {
                        Task {
                            await viewModel.loadFeedback()
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
}

#Preview {
    FeedbackResultView(
        questionText: "Describe your hometown.",
        transcript: "My hometown is very beautiful.",
        audioFileURL: nil
    )
}
