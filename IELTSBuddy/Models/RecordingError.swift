//
//  RecordingError.swift
//  IELTSBuddy
//

import Foundation

/// Typed failures for the recording / speech-recognition flow.
enum RecordingError: Equatable {
    case microphonePermissionDenied
    case speechPermissionDenied
    case speechPermissionRestricted
    case speechPermissionNotDetermined
    case speechRecognizerUnavailable
    case speechNotAuthorized
    case audioSessionSetupFailed
    case audioEngineStartFailed
    case audioFileWriteFailed
    case recognitionFailed

    /// User-facing copy for the transcript card and banners.
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
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available for your language on this device."
        case .speechNotAuthorized:
            return "Speech recognition is not allowed yet. Grant permission in Settings, then try again."
        case .audioSessionSetupFailed:
            return "Could not prepare the microphone for recording. Close other audio apps and try again."
        case .audioEngineStartFailed:
            return "Could not start recording. Check that no other app is using the microphone."
        case .audioFileWriteFailed:
            return "Could not save your recording. Please try again."
        case .recognitionFailed:
            return "Speech recognition stopped unexpectedly. Please record your answer again."
        }
    }

    /// Short label for accessibility or UI.
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
        }
    }

    /// Whether the user can resolve this from the Settings app.
    var opensSettingsWhenActionTapped: Bool {
        switch self {
        case .microphonePermissionDenied, .speechPermissionDenied, .speechNotAuthorized:
            return true
        default:
            return false
        }
    }

    /// Maps system errors from AVFoundation / Speech into stable app errors.
    static func from(_ error: Error) -> RecordingError {
        let ns = error as NSError

        if ns.domain == NSOSStatusErrorDomain {
            return .audioSessionSetupFailed
        }

        if ns.domain == "kAFAssistantErrorDomain" {
            switch ns.code {
            case 216:
                return .recognitionFailed
            case 1700:
                return .speechRecognizerUnavailable
            case 203:
                return .recognitionFailed
            case 209:
                return .speechNotAuthorized
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

        return .recognitionFailed
    }
}

extension RecordingError: LocalizedError {
    var errorDescription: String? { userMessage }
}
