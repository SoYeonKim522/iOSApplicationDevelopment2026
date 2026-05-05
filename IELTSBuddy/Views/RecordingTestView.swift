//
//  RecordingTestView.swift
//  IELTSBuddy
//

import SwiftUI

struct RecordingTestView: View {
    @StateObject private var manager = SpeechRecognitionManager()

    @State private var selectedTopic: TopicCategory = .work
    @State private var selectedPart: PartType = .part1
    @State private var currentQuestion: PracticeQuestion?

    @State private var questionGeneratorError: String?
    @State private var isGeneratingQuestion = false
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
                Picker("Topic", selection: $selectedTopic) {
                    ForEach(TopicCategory.allCases, id: \.self) { topic in
                        Text(topic.rawValue).tag(topic)
                    }
                }

                Picker("Part", selection: $selectedPart) {
                    ForEach(PartType.allCases, id: \.self) { part in
                        Text(part.rawValue).tag(part)
                    }
                }

                Button("Generate Question") {
                    Task { await generateQuestionTapped() }
                }
                .disabled(isGeneratingQuestion)

                Text(currentQuestion?.text ?? "No question generated yet.")

                if let message = questionGeneratorError {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Divider()

                if let error = manager.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                ScrollView {
                    Text(manager.transcript.isEmpty ? "Start speaking..." : manager.transcript)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .foregroundStyle(manager.transcript.isEmpty ? .secondary : .primary)
                }
                .frame(maxHeight: .infinity)

                Text(formattedRecordingTime)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let feedbackError {
                    Text(feedbackError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Button(manager.isRecording ? "Stop Recording" : "Start Recording") {
                    if manager.isRecording {
                        let trimmedTranscript = manager.transcript.trimmingCharacters(in: .whitespacesAndNewlines)

                        if trimmedTranscript.isEmpty {
                            manager.stopRecording()
                            stopTimer()
                            recordingTime = 0
                            feedbackError = "Please speak something before stopping."
                            navigateToFeedback = false
                        } else {
                            manager.stopRecording()
                            stopTimer()
                            feedbackError = nil
                            navigateToFeedback = true
                        }
                    } else {
                        feedbackError = nil
                        manager.startRecording()
                        startTimer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Recording Test")
            .navigationDestination(isPresented: $navigateToFeedback) {
                FeedbackResultView(
                    questionText: currentQuestion?.text ?? "",
                    transcript: manager.transcript
                )
            }
        }
        .padding()
        .onAppear {
            Task {
                await manager.requestPermissions()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    @MainActor
    private func generateQuestionTapped() async {
        isGeneratingQuestion = true
        defer { isGeneratingQuestion = false }
        questionGeneratorError = nil

        do {
            currentQuestion = try await questionGenerator.generateQuestion(
                topic: selectedTopic.rawValue,
                part: selectedPart.rawValue
            )
        } catch {
            questionGeneratorError = error.localizedDescription
        }
    }

    private func startTimer() {
        stopTimer()
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            recordingTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    RecordingTestView()
}
