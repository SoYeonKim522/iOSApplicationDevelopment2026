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
    @Published private(set) var isGeneratingQuestion: Bool = false
    @Published private(set) var recordingTime: Int = 0
    @Published private(set) var hasStartedRecordingAttempt = false

    @Published private(set) var transcript: String = ""
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var activeError: RecordingError?
    @Published private(set) var activeErrorPlacement: RecordingErrorPlacement?
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

    func preparePracticeEntry(topic: TopicCategory, part: PartType) {
        selectedTopic = topic
        selectedPart = part
        clearActiveError()
        currentQuestion = nil
        transcript = ""
        audioFileURL = nil
        hasStartedRecordingAttempt = false
        recordingTime = 0
        stopTimer()
    }

    func generateQuestionTapped() async {
        isGeneratingQuestion = true
        defer { isGeneratingQuestion = false }
        clearActiveError(for: .questionGeneration)

        do {
            currentQuestion = try await questionGenerator.generateQuestion(
                topic: selectedTopic,
                part: selectedPart
            )
        } catch let serviceError as QuestionGeneratorServiceError {
            setActiveError(RecordingError.from(serviceError), placement: .questionGeneration)
        } catch {
            setActiveError(.unknown, placement: .questionGeneration)
        }
    }

    func retryQuestionGeneration() async {
        await generateQuestionTapped()
    }

    func toggleRecording() {
        if isRecording {
            stopRecordingAndHandleNavigation()
        } else {
            hasStartedRecordingAttempt = true
            clearActiveError(for: .practiceAction)
            manager.startRecording()
            startTimer()
        }
    }

    func cleanup() {
        stopTimer()
    }

    func clearActiveError() {
        activeError = nil
        activeErrorPlacement = nil
    }

    func clearActiveError(for placement: RecordingErrorPlacement) {
        guard activeErrorPlacement == placement else { return }
        activeError = nil
        activeErrorPlacement = nil
    }

    private func setActiveError(_ error: RecordingError, placement: RecordingErrorPlacement) {
        activeError = error
        activeErrorPlacement = placement
    }

    private func bindManager() {
        manager.transcriptPublisher
            .sink { [weak self] in self?.transcript = $0 }
            .store(in: &cancellables)

        manager.isRecordingPublisher
            .sink { [weak self] in self?.isRecording = $0 }
            .store(in: &cancellables)

        manager.recordingErrorPublisher
            .sink { [weak self] error in
                guard let self else { return }
                if let error {
                    guard self.activeErrorPlacement != .practiceAction else { return }
                    self.setActiveError(error, placement: .recording)
                } else if self.activeErrorPlacement == .recording {
                    self.clearActiveError()
                }
            }
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
            setActiveError(.emptyTranscript, placement: .practiceAction)
            return
        }

        clearActiveError(for: .practiceAction)
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
        clearActiveError()
        currentQuestion = nil
        recordingTime = 0
    }
}
