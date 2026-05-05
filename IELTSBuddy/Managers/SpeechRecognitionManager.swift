//
//  SpeechRecognitionManager.swift
//  IELTSBuddy
//

import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognitionManager: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?

    var audioFileURL: URL?
    var audioFile: AVAudioFile?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioTapInstalled = false
    private let speechRecognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale(identifier: Locale.current.identifier)) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestPermissions() async {
        errorMessage = nil

        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            errorMessage = "Microphone access is required to record your practice."
            return
        }

        let speechStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        switch speechStatus {
        case .authorized:
            break
        case .denied:
            errorMessage = "Speech recognition was denied. Enable it in Settings → Privacy & Security → Speech Recognition."
        case .restricted:
            errorMessage = "Speech recognition is restricted on this device."
        case .notDetermined:
            errorMessage = "Speech recognition permission is not available."
        @unknown default:
            errorMessage = "Speech recognition is not available."
        }
    }

    func startRecording() {
        errorMessage = nil

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available for this language."
            return
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition is not authorized."
            return
        }

        guard !isRecording, !audioEngine.isRunning else { return }

        Task { @MainActor in
            let micGranted = await AVAudioApplication.requestRecordPermission()
            guard micGranted else {
                errorMessage = "Microphone access is required to record your practice."
                return
            }

            do {
                try self.startRecognitionSession(using: speechRecognizer)
            } catch {
                errorMessage = error.localizedDescription
                self.cleanupAfterFailure()
            }
        }
    }

    func stopRecording() {
        // stop mic input
        if audioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioTapInstalled = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // end audio
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // close file handle to flush to disk
        audioFile = nil

        // deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
    }

    private func cleanupAfterFailure() {
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

    private func startRecognitionSession(using speechRecognizer: SFSpeechRecognizer) throws {
        stopRecording()

        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let audioFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording-\(UUID().uuidString).caf")
        self.audioFileURL = audioFileURL
        self.audioFile = try AVAudioFile(forWriting: audioFileURL, settings: recordingFormat.settings)
        let recognitionRequestForTap = recognitionRequest
        let audioFileForTap = self.audioFile

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequestForTap.append(buffer)
            if let audioFileForTap {
                do {
                    try audioFileForTap.write(from: buffer)
                } catch {
                    Task { @MainActor in
                        if self?.errorMessage == nil {
                            self?.errorMessage = "Unable to save recorded audio."
                        }
                    }
                }
            }
        }
        audioTapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if let error {
                    if self.shouldReportRecognitionError(error) {
                        self.errorMessage = error.localizedDescription
                    }
                    if self.isRecording {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    private func shouldReportRecognitionError(_ error: Error) -> Bool {
        let ns = error as NSError
        // Canceled when the recognition task ends (e.g. user stopped recording).
        if ns.domain == "kAFAssistantErrorDomain", ns.code == 216 {
            return false
        }
        return true
    }
}
