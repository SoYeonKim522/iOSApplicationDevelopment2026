//
//  AppServices.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 14/5/2026.
//

import Foundation

struct AppServices {
    let questionGenerator: any QuestionGenerating
    let aiFeedback: any AIFeedbackProviding
    let speechManager: any SpeechRecognitionManaging
}

//for preview
extension AppServices {
    static let preview = AppServices(
        questionGenerator: MockQuestionGeneratorService(),
        aiFeedback: MockAIFeedbackService(),
        speechManager: SpeechRecognitionManager()
    )
}
