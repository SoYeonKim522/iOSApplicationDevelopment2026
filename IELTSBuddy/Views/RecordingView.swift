//
//  RecordingView.swift
//  IELTSBuddy
//

import SwiftUI
import UIKit

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    var onNavigate: (Route) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Question Generator")
                            .font(.headline)

                        HStack(spacing: 8) {
                            MenuPicker(title: "Topic", selection: $viewModel.selectedTopic)
                            MenuPicker(title: "Part", selection: $viewModel.selectedPart)
                        }
                        
                        Button("Generate Question") {
                            Task { await viewModel.generateQuestionTapped() }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.isGeneratingQuestion
                            ? Color.gray.opacity(0.35)
                            : Color.accentColor
                        )
                        .foregroundStyle(.white)
                        .font(.headline)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(viewModel.isGeneratingQuestion)
                    }
                    .recordingCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Question")
                            .font(.headline)

                        if viewModel.isGeneratingQuestion {
                            ProgressView("Generating question...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        } else if let currentQuestion = viewModel.currentQuestion {
                            Text(currentQuestion.text)
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if currentQuestion.estimatedDuration > 0 {
                                Text("\(currentQuestion.estimatedDuration) seconds")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "questionmark.bubble")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                Text("No question generated yet")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Text("Tap Generate Question to begin.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                        }

                        if let message = viewModel.questionGeneratorError {
                            HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text(message)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .recordingCardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcript")
                            .font(.headline)

                        ScrollView {
                            VStack(alignment: .leading) {
                                Text(
                                    viewModel.hasStartedRecordingAttempt
                                    ? (viewModel.transcript.isEmpty ? "Start speaking..." : viewModel.transcript)
                                    : ""
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(height: 180)

                        
                    }
                    .recordingCardStyle()
                }
                .padding(.bottom, 4)
                .padding(.horizontal, 2)
            }
            
            if let error = viewModel.recordingError {
                RecordingErrorBanner(error: error) {
                    viewModel.clearRecordingError()
                }
            }

            Text(viewModel.formattedRecordingTime)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)

            if let feedbackError = viewModel.feedbackError {
                HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(feedbackError)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
            }

            Button(viewModel.isRecording ? "Stop Recording" : "Start Recording") {
                viewModel.toggleRecording()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                viewModel.canTapRecordButton
                ? Color.accentColor
                : Color.gray.opacity(0.5)
            )
            .foregroundStyle(.white)
            .font(.headline)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!viewModel.canTapRecordButton)
        }
        .padding()
        .navigationTitle("Let's practice")
        .onAppear {
            Task {
                await viewModel.requestPermissions()
            }
            
            viewModel.onNavigateToFeedback = {
                onNavigate(Route.feedback(
                    question: viewModel.currentQuestionText,
                    transcript: viewModel.transcript,
                    url: viewModel.audioFileURL
                ))
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .toolbar(.hidden, for: .tabBar)

    }
}

private extension View {
    func recordingCardStyle() -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct MenuPicker<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T

    var body: some View {
        Menu {
            ForEach(Array(T.allCases), id: \.self) { option in
                Button(option.rawValue) { selection = option }
            }
        } label: {
            HStack {
                Text(selection.rawValue)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RecordingErrorBanner: View {
    let error: RecordingError
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(error.userMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss error")
            }

            if error.opensSettingsWhenActionTapped {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(error.title). \(error.userMessage)")
    }

    private var iconName: String {
        switch error {
        case .microphonePermissionDenied, .speechPermissionDenied, .speechNotAuthorized:
            return "lock.fill"
        case .speechPermissionRestricted, .speechPermissionNotDetermined, .speechRecognizerUnavailable:
            return "mic.slash.fill"
        case .audioSessionSetupFailed, .audioEngineStartFailed, .audioFileWriteFailed, .recognitionFailed:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView(
            viewModel: RecordingViewModel(),
            onNavigate: { _ in }
        )
    }
}
