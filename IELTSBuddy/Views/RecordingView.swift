//
//  RecordingTestView.swift
//  IELTSBuddy
//

import SwiftUI

struct RecordingTestView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    @State private var recordingTime: Int = 0
    @State private var timer: Timer?
    @State private var navigateToFeedback = false
    @State private var feedbackError: String?

    private let questionGenerator = QuestionGeneratorService()

    private var formattedRecordingTime: String {
        let minutes = recordingTime / 60
        let seconds = recordingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                
                Picker("Topic", selection: $viewModel.selectedTopic) {
                    ForEach(TopicCategory.allCases, id: \.self) { topic in
                        Text(topic.rawValue).tag(topic)
                    }
                }

                Picker("Part", selection: $viewModel.selectedPart) {
                    ForEach(PartType.allCases, id: \.self) { part in
                        Text(part.rawValue).tag(part)
                    }
                }
                
                Button("Generate Question") {
                    Task { await viewModel.generateQuestionTapped() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGeneratingQuestion)
                
                if viewModel.isGeneratingQuestion {
                    ProgressView("Generating question...")
                } else if let currentQuestion = viewModel.currentQuestion {
                    Text(currentQuestion.text)
                } else {
                    Text("No question generated yet.")
                        .foregroundStyle(.secondary)
                }

                if let message = viewModel.questionGeneratorError {
                    
                    Text(message)
                        .foregroundStyle(.red)
                }

                Divider()

                if let error = viewModel.managerErrorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                ScrollView {
                    Text(viewModel.transcript.isEmpty ? "Start speaking..." : viewModel.transcript)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .foregroundStyle(viewModel.transcript.isEmpty ? .secondary : .primary)
                }
                .frame(maxHeight: .infinity)

                Text(viewModel.formattedRecordingTime)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let feedbackError = viewModel.feedbackError {
                    Text(feedbackError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button(viewModel.isRecording ? "Stop Recording" : "Start Recording") {
                    viewModel.toggleRecording()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canTapRecordButton)
            }
            .navigationTitle("Recording Test")
            .navigationDestination(isPresented: $viewModel.navigateToFeedback) {
                FeedbackResultView(
                    questionText: viewModel.currentQuestionText,
                    transcript: viewModel.transcript,
                    audioFileURL: viewModel.audioFileURL
                )
            }
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.requestPermissions()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    RecordingTestView()
}
