//
//  IELTSBuddyApp.swift
//  IELTSBuddy
//
//  Created by yosam on 3/5/2026.
//

import SwiftUI

@main
struct IELTSBuddyApp: App {
    private let services = AppServices.make()
    
    var body: some Scene {
        WindowGroup {
            RootView(services: services)
        }
    }
}

extension AppServices {
    @MainActor
    static func make() -> AppServices {
        #if DEBUG
        if ProcessInfo.processInfo.environment["USE_MOCK_API"] == "1" {
            return AppServices(
                questionGenerator: MockQuestionGeneratorService(),
                aiFeedback: MockAIFeedbackService(),
                speechManager: SpeechRecognitionManager()
            )
        }
        #endif
        return AppServices(
            questionGenerator: QuestionGeneratorService(),
            aiFeedback: AIFeedbackService(),
            speechManager: SpeechRecognitionManager()
        )
    }
}
