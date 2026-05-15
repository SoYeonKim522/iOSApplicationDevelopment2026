//
//  RecordingViewModel.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 9/5/2026.
//

import Combine
import Foundation

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published var selectedTopic: TopicCategory = .work
    @Published var selectedPart: PartType = .part1
    @Published private(set) var currentQuestion: PracticeQuestion?
    @Published private(set) var questionGeneratorError: String?
    @Published private(set) var isGeneratingQuestion: Bool = false
    @Published private(set) var recordingTime: Int = 0
    @Published private(set) var feedbackError: String?
    @Published private(set) var hasStartedRecordingAttempt = false

    @Published private(set) var transcript: String = ""
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var recordingError: RecordingError?
    @Published private(set) var audioFileURL: URL?
    
    var onNavigateToFeedback: (() -> Void)?

    var formattedRecordingTime: String {
        let minutes = recordingTime / 60
        let seconds = recordingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var currentQuestionText: String {
        currentQuestion?.text ?? ""
    }

    var canTapRecordButton: Bool {
        isRecording || currentQuestion != nil
    }

    private let manager: any SpeechRecognitionManaging
    private let questionGenerator: any QuestionGenerating
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(
        manager: (any SpeechRecognitionManaging)? = nil,
        questionGenerator: (any QuestionGenerating)? = nil
    ) {
        self.manager = manager ?? SpeechRecognitionManager()
        self.questionGenerator = questionGenerator ?? QuestionGeneratorService()
        bindManager()
    }

    func requestPermissions() async {
        await manager.requestPermissions()
    }

    // Applies topic before navigating from Home shortcuts so pickers match the chosen card.
    func preparePracticeEntry(topic: TopicCategory, part: PartType) {
        selectedTopic = topic
        selectedPart = part
        questionGeneratorError = nil
        currentQuestion = nil
        feedbackError = nil
        recordingError = nil
        transcript = ""
        audioFileURL = nil
        hasStartedRecordingAttempt = false
        recordingTime = 0
        stopTimer()
    }

    func generateQuestionTapped() async {
        isGeneratingQuestion = true
        defer { isGeneratingQuestion = false }
        questionGeneratorError = nil

        do {
            currentQuestion = try await questionGenerator.generateQuestion(
                topic: selectedTopic,
                part: selectedPart
            )
        } catch {
            questionGeneratorError = error.localizedDescription
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecordingAndHandleNavigation()
        } else {
            hasStartedRecordingAttempt = true
            feedbackError = nil
            manager.startRecording()
            startTimer()
        }
    }

    func cleanup() {
        stopTimer()
    }

    private func bindManager() {
        manager.transcriptPublisher
            .sink { [weak self] in self?.transcript = $0 }
            .store(in: &cancellables)

        manager.isRecordingPublisher
            .sink { [weak self] in self?.isRecording = $0 }
            .store(in: &cancellables)

        manager.recordingErrorPublisher
            .sink { [weak self] in self?.recordingError = $0 }
            .store(in: &cancellables)
        
        manager.isRecordingPublisher
            .sink { [weak self] _ in
                self?.audioFileURL = self?.manager.audioFileURL
            }
            .store(in: &cancellables)
    }
    
    private func stopRecordingAndHandleNavigation() {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        manager.stopRecording()
        stopTimer()

        if trimmedTranscript.isEmpty {
            recordingTime = 0
            feedbackError = "Please speak something before stopping."
            return
        }

        feedbackError = nil
        onNavigateToFeedback?()
    }

    private func startTimer() {
        stopTimer()
        recordingTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            Task { @MainActor in
                self.recordingTime += 1
            }
        }
    }


    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func resetForNextQuestion() {
        transcript = ""
        audioFileURL = nil
        hasStartedRecordingAttempt = false
        feedbackError = nil
        recordingError = nil
        currentQuestion = nil
        recordingTime = 0
    }

    func clearRecordingError() {
        recordingError = nil
    }
}
