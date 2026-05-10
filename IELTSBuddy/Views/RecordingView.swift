//
//  RecordingView.swift
//  IELTSBuddy
//

import SwiftUI
import UIKit

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    var onNavigate: (Route) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(spacing: 12) {
                Picker("Topic", selection: $viewModel.selectedTopic) {
                    ForEach(TopicCategory.allCases, id: \.self) { topic in
                        Text(topic.rawValue).tag(topic)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                Picker("Part", selection: $viewModel.selectedPart) {
                    ForEach(PartType.allCases, id: \.self) { part in
                        Text(part.rawValue).tag(part)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
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
                if viewModel.transcript.isEmpty {
                    // Show "Start speaking..." after the user has attempted to record
                    if viewModel.hasStartedRecordingAttempt {
                        Text("Start speaking...")
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .topLeading
                            )
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(viewModel.transcript)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                        .foregroundStyle(.primary)
                }
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
        .navigationTitle("Let's Practice")
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

#Preview {
    NavigationStack {
        RecordingView(onNavigate: { _ in })
    }
}
