//
//  RecordingError.swift
//  IELTSBuddy
//

import Foundation

/// Where on the recording screen an error should be shown.
enum RecordingErrorPlacement: Equatable {
    case questionGeneration
    case recording
    case practiceAction
}

/// Typed failures for the recording practice flow (speech, questions, validation).
enum RecordingError: Equatable {
    // MARK: Permissions
    case microphonePermissionDenied
    case speechPermissionDenied
    case speechPermissionRestricted
    case speechPermissionNotDetermined
    case speechNotAuthorized

    // MARK: Speech / audio hardware
    case speechRecognizerUnavailable
    case audioSessionSetupFailed
    case audioEngineStartFailed
    case audioFileWriteFailed
    case recognitionFailed

    // MARK: Question API / network
    case authenticationError
    case networkFailure
    case decodingError

    // MARK: Practice flow
    case emptyTranscript

    // MARK: Fallback
    case unknown

    var userMessage: String {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is turned off. Enable it in Settings to record your answer."
        case .speechPermissionDenied:
            return "Speech recognition is turned off. Enable it in Settings → Privacy & Security → Speech Recognition."
        case .speechPermissionRestricted:
            return "Speech recognition is restricted on this device and cannot be used."
        case .speechPermissionNotDetermined:
            return "Speech recognition permission is required. Try again and allow access when prompted."
        case .speechNotAuthorized:
            return "Speech recognition is not allowed yet. Grant permission in Settings, then try again."
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available for your language on this device."
        case .audioSessionSetupFailed:
            return "Could not prepare the microphone for recording. Close other audio apps and try again."
        case .audioEngineStartFailed:
            return "Could not start recording. Check that no other app is using the microphone."
        case .audioFileWriteFailed:
            return "Could not save your recording. Please try again."
        case .recognitionFailed:
            return "Speech recognition stopped unexpectedly. Please record your answer again."
        case .authenticationError:
            return "The app could not authenticate with the question service. Check your API key configuration."
        case .networkFailure:
            return "Could not reach the server. Check your internet connection and try again."
        case .decodingError:
            return "Received an unexpected response from the server. Please try generating a question again."
        case .emptyTranscript:
            return "Please speak something before stopping."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    var title: String {
        switch self {
        case .microphonePermissionDenied, .speechPermissionDenied, .speechNotAuthorized:
            return "Permission required"
        case .speechPermissionRestricted, .speechPermissionNotDetermined:
            return "Speech recognition unavailable"
        case .speechRecognizerUnavailable:
            return "Language not supported"
        case .audioSessionSetupFailed, .audioEngineStartFailed:
            return "Recording setup failed"
        case .audioFileWriteFailed:
            return "Could not save audio"
        case .recognitionFailed:
            return "Recognition failed"
        case .authenticationError:
            return "Authentication failed"
        case .networkFailure:
            return "Connection problem"
        case .decodingError:
            return "Invalid response"
        case .emptyTranscript:
            return "No speech detected"
        case .unknown:
            return "Something went wrong"
        }
    }

    var opensSettingsWhenActionTapped: Bool {
        switch self {
        case .microphonePermissionDenied, .speechPermissionDenied, .speechNotAuthorized:
            return true
        default:
            return false
        }
    }

    var showsRetryAction: Bool {
        switch self {
        case .networkFailure, .decodingError, .recognitionFailed,
             .audioSessionSetupFailed, .audioEngineStartFailed, .audioFileWriteFailed, .unknown:
            return true
        default:
            return false
        }
    }

    // MARK: - Service mappers

    static func from(_ error: QuestionGeneratorServiceError) -> RecordingError {
        switch error {
        case .missingAPIKey:
            return .authenticationError
        case .networkFailed:
            return .networkFailure
        case .decodingFailed:
            return .decodingError
        case .httpFailure(let statusCode, _):
            if statusCode == 401 || statusCode == 403 {
                return .authenticationError
            }
            if (500 ... 599).contains(statusCode) {
                return .networkFailure
            }
            return .unknown
        case .invalidURL, .invalidResponse, .emptyModelContent:
            return .decodingError
        }
    }

    /// Maps system errors from AVFoundation / Speech into stable app errors.
    static func from(_ error: Error) -> RecordingError {
        if let serviceError = error as? QuestionGeneratorServiceError {
            return from(serviceError)
        }

        let ns = error as NSError

        if ns.domain == NSURLErrorDomain {
            return .networkFailure
        }

        if ns.domain == NSOSStatusErrorDomain {
            return .audioSessionSetupFailed
        }

        if ns.domain == "kAFAssistantErrorDomain" {
            switch ns.code {
            case 1700:
                return .speechRecognizerUnavailable
            case 209:
                return .speechNotAuthorized
            case 216, 203:
                return .recognitionFailed
            default:
                break
            }
        }

        if ns.domain == "com.apple.SpeechRecognitionErrorDomain" {
            return .recognitionFailed
        }

        let description = error.localizedDescription.lowercased()
        if description.contains("permission") || description.contains("authorized") {
            return .speechNotAuthorized
        }
        if description.contains("denied") {
            return .microphonePermissionDenied
        }

        return .unknown
    }
}

extension RecordingError: LocalizedError {
    var errorDescription: String? { userMessage }
}
