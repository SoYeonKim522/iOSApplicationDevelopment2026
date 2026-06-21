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
                            .foregroundStyle(Color.appTextPrimary)

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
                            ? Color.appTextSecondary.opacity(0.35)
                            : Color.appPrimary
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
                            .foregroundStyle(Color.appTextPrimary)

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
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "questionmark.bubble")
                                    .font(.title3)
                                    .foregroundStyle(Color.appTextSecondary)
                                Text("No question generated yet")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.appTextSecondary)
                                Text("Tap Generate Question to begin.")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextSecondary)
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
                            .foregroundStyle(Color.appTextPrimary)

                        ScrollView {
                            VStack(alignment: .leading) {
                                Text(
                                    viewModel.hasStartedRecordingAttempt
                                    ? (viewModel.transcript.isEmpty ? "Start speaking..." : viewModel.transcript)
                                    : "Your transcript will appear here"
                                )
                                .foregroundStyle(viewModel.transcript.isEmpty ? Color.appTextSecondary : Color.appTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(4)
                            }
                            .padding(12)
                        }
                        .frame(height: 180)
                        .background(Color.appInnerField)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.vertical, 8)

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
                .font(.title)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            if let error = viewModel.activeError,
               viewModel.activeErrorPlacement == .practiceAction {
                RecordingErrorBanner(
                    error: error,
                    onDismiss: { viewModel.clearActiveError(for: .practiceAction) }
                )
            }

            Button {
                viewModel.toggleRecording()
            } label: {
                Label(
                    viewModel.isRecording ? "Stop Recording" : "Start Recording",
                    systemImage: viewModel.isRecording ? "square.fill" : "mic"
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                viewModel.canTapRecordButton
                ? Color.appPrimary
                : Color.appTextSecondary.opacity(0.5)
            )
            .foregroundStyle(.white)
            .font(.headline)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!viewModel.canTapRecordButton)
        }
        .padding()
        .background(Color.appBackground)
        .navigationTitle("Let's practice")
        .onAppear {
            Task {
                await viewModel.requestPermissions()
            }

            viewModel.onNavigateToFeedback = {
                guard let attempt = viewModel.makeSpeakingAttempt() else { return }
                AttemptMediaStore.shared.register(attempt)
                onNavigate(Route.feedback(attemptId: attempt.id))
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
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appTextPrimary.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 10,
                x: 0,
                y: 4
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
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.appInnerField)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.appTextPrimary.opacity(0.2), lineWidth: 1)
            )
            .foregroundStyle(Color.appPrimary)
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
                        .foregroundStyle(Color.appTextPrimary)
                    Text(error.userMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
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
                    .tint(Color.appPrimary)
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
