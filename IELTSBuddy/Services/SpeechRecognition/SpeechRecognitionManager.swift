//
//  SpeechRecognitionManager.swift
//  IELTSBuddy
//

import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognitionManager: ObservableObject, SpeechRecognitionManaging {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published private(set) var recordingError: RecordingError?

    var transcriptPublisher: AnyPublisher<String, Never> { $transcript.eraseToAnyPublisher() }
    var isRecordingPublisher: AnyPublisher<Bool, Never> { $isRecording.eraseToAnyPublisher() }
    var recordingErrorPublisher: AnyPublisher<RecordingError?, Never> { $recordingError.eraseToAnyPublisher() }

    var audioFileURL: URL?
    var audioFile: AVAudioFile?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioTapInstalled = false
    /// True while audio has ended and we wait for the recognition task to finish (final result or benign completion).
    private var isAwaitingRecognitionFinish = false
    private let speechRecognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale(identifier: Locale.current.identifier)) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestPermissions() async {
        recordingError = nil

        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            recordingError = .microphonePermissionDenied
            return
        }

        let speechStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        recordingError = Self.recordingError(forSpeechAuthorization: speechStatus)
    }

    func startRecording() {
        recordingError = nil

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            recordingError = .speechRecognizerUnavailable
            return
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            break
        case .denied:
            recordingError = .speechPermissionDenied
            return
        case .restricted:
            recordingError = .speechPermissionRestricted
            return
        case .notDetermined:
            recordingError = .speechPermissionNotDetermined
            return
        @unknown default:
            recordingError = .speechNotAuthorized
            return
        }

        guard !isRecording, !audioEngine.isRunning else { return }

        Task { @MainActor in
            let micGranted = await AVAudioApplication.requestRecordPermission()
            guard micGranted else {
                recordingError = .microphonePermissionDenied
                return
            }

            do {
                try self.startRecognitionSession(using: speechRecognizer)
            } catch {
                recordingError = Self.recordingError(forSessionStart: error)
                self.cleanupAfterFailure()
            }
        }
    }

    func stopRecording() {
        guard isRecording || audioEngine.isRunning || audioTapInstalled else {
            return
        }

        isAwaitingRecognitionFinish = true

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }

        recognitionRequest?.endAudio()

        audioFile = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
    }

    private func cleanupAfterFailure() {
        isAwaitingRecognitionFinish = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioFile = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }

    /// Tear down any in-flight session before starting a new recording (cancels recognition).
    private func resetSessionForNewRecording() {
        isAwaitingRecognitionFinish = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioFile = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }

    private func finalizeRecognitionAfterStop() {
        recognitionTask = nil
        recognitionRequest = nil
        isAwaitingRecognitionFinish = false
    }

    private func startRecognitionSession(using speechRecognizer: SFSpeechRecognizer) throws {
        resetSessionForNewRecording()

        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .record,
                mode: .measurement
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SessionStartFailure.audioSession(error)
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let audioFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString).caf")
        self.audioFileURL = audioFileURL

        do {
            self.audioFile = try AVAudioFile(forWriting: audioFileURL, settings: recordingFormat.settings)
        } catch {
            throw SessionStartFailure.audioFile(error)
        }

        let recognitionRequestForTap = recognitionRequest
        let audioFileForTap = self.audioFile

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequestForTap.append(buffer)
            if let audioFileForTap {
                do {
                    try audioFileForTap.write(from: buffer)
                } catch {
                    Task { @MainActor in
                        if self?.recordingError == nil {
                            self?.recordingError = .audioFileWriteFailed
                        }
                    }
                }
            }
        }
        audioTapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw SessionStartFailure.audioEngine(error)
        }

        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.finalizeRecognitionAfterStop()
                    }
                }

                if let error {
                    let benignWhileStopping = self.isAwaitingRecognitionFinish && self.isBenignRecognitionEndError(error)

                    if !benignWhileStopping, self.shouldReportRecognitionError(error) {
                        self.recordingError = RecordingError.from(error)
                    }

                    if benignWhileStopping {
                        self.finalizeRecognitionAfterStop()
                    } else if self.isRecording {
                        self.cleanupAfterFailure()
                    } else if self.isAwaitingRecognitionFinish {
                        self.finalizeRecognitionAfterStop()
                    }
                }
            }
        }
    }

    private enum SessionStartFailure: Error {
        case audioSession(Error)
        case audioFile(Error)
        case audioEngine(Error)
    }

    private static func recordingError(forSpeechAuthorization status: SFSpeechRecognizerAuthorizationStatus) -> RecordingError? {
        switch status {
        case .authorized:
            return nil
        case .denied:
            return .speechPermissionDenied
        case .restricted:
            return .speechPermissionRestricted
        case .notDetermined:
            return .speechPermissionNotDetermined
        @unknown default:
            return .speechNotAuthorized
        }
    }

    private static func recordingError(forSessionStart error: Error) -> RecordingError {
        if let failure = error as? SessionStartFailure {
            switch failure {
            case .audioSession:
                return .audioSessionSetupFailed
            case .audioFile:
                return .audioFileWriteFailed
            case .audioEngine:
                return .audioEngineStartFailed
            }
        }
        return RecordingError.from(error)
    }

    private func isBenignRecognitionEndError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == "kAFAssistantErrorDomain", ns.code == 216 {
            return true
        }
        let description = error.localizedDescription.lowercased()
        if description.contains("canceled") || description.contains("cancelled") {
            return true
        }
        return false
    }

    private func shouldReportRecognitionError(_ error: Error) -> Bool {
        let ns = error as NSError
        // Canceled when the recognition task ends (e.g. user stopped recording).
        if ns.domain == "kAFAssistantErrorDomain", ns.code == 216 {
            return false
        }
        let description = error.localizedDescription.lowercased()
        if description.contains("canceled") || description.contains("cancelled") {
            return false
        }
        return true
    }
}
