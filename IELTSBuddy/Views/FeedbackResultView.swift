//
//  FeedbackResultView.swift
//  IELTSBuddy
//

import SwiftUI

struct FeedbackResultView: View {

    let questionText: String
    let transcript: String
    let audioFileURL: URL?
    let onExitToRoot: () -> Void //'x' button
    let onNextQuestion: () -> Void

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: FeedbackResultViewModel

    init(
        questionText: String,
        transcript: String,
        audioFileURL: URL?,
        onExitToRoot: @escaping () -> Void,
        onNextQuestion: @escaping () -> Void
    ) {
        self.questionText = questionText
        self.transcript = transcript
        self.audioFileURL = audioFileURL
        self.onExitToRoot = onExitToRoot
        self.onNextQuestion = onNextQuestion

        _viewModel = StateObject(
            wrappedValue: FeedbackResultViewModel(
                questionText: questionText,
                transcript: transcript,
                audioFileURL: audioFileURL
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Analyzing your answer...")
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding()
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                        Text("Something went wrong")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding()
            } else if let feedback = viewModel.feedbackResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        transcriptSection
                            .padding(.top, -20)
                        scoresSection(feedback)
                        aiAnalysisSection(feedback)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Feedback")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onExitToRoot()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .task {
            await viewModel.loadFeedback()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .safeAreaInset(edge: .bottom) {
            bottomInset
        }
    }

    @ViewBuilder
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: -10) {
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
                .accessibilityLabel(viewModel.isPlaying ? "Stop playback" : "Play recording")
            }
            
            Text(transcript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func scoresSection(_ feedback: AIFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", feedback.overallScore))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("overall")
                        .font(.body)
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                PillarScoreCell(title: "Fluency", score: feedback.fluencyScore)
                PillarScoreCell(title: "Vocabulary", score: feedback.vocabularyScore)
                PillarScoreCell(title: "Grammar", score: feedback.grammarScore)
                PillarScoreCell(title: "Pronunciation", score: feedback.pronunciationScore)
            }
        }
    }

    private func aiAnalysisSection(_ feedback: AIFeedback) -> some View {
        let comment = feedback.feedback
        let mistakeLists = feedback.aiCorrections

        return VStack(alignment: .leading, spacing: 16) {
            Text("AI Analysis")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 14) {
                analysisBlock(title: "Idea Suggestion", items: comment.ideaSuggestion)
                analysisBlock(title: "Strengths", items: comment.strengths)
                analysisBlock(title: "Weaknesses", items: comment.weaknesses)

                if !mistakeLists.isEmpty {
                    
                    Text("Key Corrections")
                        .font(.headline.weight(.semibold))
                        .padding(.top, 12)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(mistakeLists) { log in
                            mistakeSubCard(log)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }

    func analysisBlock(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
    }

    func mistakeSubCard(_ log: ReviewLog) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(log.type.rawValue.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
                Spacer()
                Button {
                    viewModel.toggleSaved(log, sessionId: viewModel.feedbackResult?.id ?? UUID())
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isBookmarked(log.id) ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 16, weight: .semibold))
                        if viewModel.isBookmarked(log.id) {
                            Text("Saved")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(viewModel.isBookmarked(log.id) ? Color.green : Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isBookmarked(log.id) ? "Saved mistake" : "Save mistake")
            }

            Text(log.original)
                .font(.subheadline)
                .foregroundStyle(Color.red.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text(log.corrected)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.green.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            if !log.explanation.isEmpty {
                Text(log.explanation)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var bottomInset: some View {
        if viewModel.isLoading {
            EmptyView()
        } else if viewModel.errorMessage != nil {
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
            HStack(spacing: 12) {
                Button {
                    dismiss()
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
                    onNextQuestion()
                } label: {
                    Text("Next Question")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                }
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 0)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
        }
    }
}



 struct PillarScoreCell: View {
    let title: String
    let score: Double

    private static let maxBand: Double = 9

    private var progress: CGFloat {
        CGFloat(min(max(score / Self.maxBand, 0), 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f", score))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(Color.accentColor.opacity(0.85))
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 4 : 0))
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        FeedbackResultView(
            questionText: "Describe your hometown.",
            transcript: "My hometown is very beautiful.",
            audioFileURL: nil,
            onExitToRoot: {},
            onNextQuestion: {}
        )
    }
}
