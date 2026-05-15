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

                        if let error = viewModel.activeError,
                           viewModel.activeErrorPlacement == .questionGeneration {
                            RecordingErrorBanner(
                                error: error,
                                onDismiss: { viewModel.clearActiveError(for: .questionGeneration) },
                                onRetry: { Task { await viewModel.retryQuestionGeneration() } }
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

                        if let error = viewModel.activeError,
                           viewModel.activeErrorPlacement == .recording,
                           !error.opensSettingsWhenActionTapped {
                            RecordingErrorBanner(
                                error: error,
                                onDismiss: { viewModel.clearActiveError(for: .recording) }
                            )
                        }
                    }
                    .recordingCardStyle()
                }
                .padding(.bottom, 4)
                .padding(.horizontal, 2)
            }

            Text(viewModel.formattedRecordingTime)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)

            if let error = viewModel.activeError,
               viewModel.activeErrorPlacement == .practiceAction {
                RecordingErrorBanner(
                    error: error,
                    onDismiss: { viewModel.clearActiveError(for: .practiceAction) }
                )
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
        .alert(
            permissionAlertTitle,
            isPresented: permissionAlertBinding,
            actions: {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) {
                    if let placement = viewModel.activeErrorPlacement {
                        viewModel.clearActiveError(for: placement)
                    }
                }
            },
            message: {
                if let error = viewModel.activeError {
                    Text(error.userMessage)
                }
            }
        )
    }

    private var permissionAlertTitle: String {
        viewModel.activeError?.title ?? "Permission required"
    }

    private var permissionAlertBinding: Binding<Bool> {
        Binding(
            get: {
                guard let error = viewModel.activeError else { return false }
                return error.opensSettingsWhenActionTapped
                    && viewModel.activeErrorPlacement == .recording
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearActiveError(for: .recording)
                }
            }
        )
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
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
    var onRetry: (() -> Void)? = nil

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

            HStack(spacing: 8) {
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

                if error.showsRetryAction, let onRetry {
                    Button(action: onRetry) {
                        Text(retryButtonTitle)
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
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

    private var retryButtonTitle: String {
        switch error {
        case .networkFailure:
            return "Retry connection"
        case .decodingError:
            return "Try again"
        default:
            return "Retry"
        }
    }

    private var iconName: String {
        switch error {
        case .microphonePermissionDenied, .speechPermissionDenied, .speechNotAuthorized, .authenticationError:
            return "lock.fill"
        case .speechPermissionRestricted, .speechPermissionNotDetermined, .speechRecognizerUnavailable:
            return "mic.slash.fill"
        case .networkFailure:
            return "wifi.exclamationmark"
        case .decodingError:
            return "doc.text.magnifyingglass"
        case .emptyTranscript:
            return "waveform"
        case .audioSessionSetupFailed, .audioEngineStartFailed, .audioFileWriteFailed,
             .recognitionFailed, .unknown:
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
