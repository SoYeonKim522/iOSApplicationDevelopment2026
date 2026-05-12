//
//  AIFeedback.swift
//  IELTSBuddy
//

import Foundation

struct FeedbackComment: Codable, Equatable {
    let strengths: [String]
    let weaknesses: [String]
    let ideaSuggestion: [String]
}

struct AIFeedback: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let questionText: String
    let userAnswer: String
    let overallScore: Double
    let fluencyScore: Double
    let vocabularyScore: Double
    let grammarScore: Double
    let pronunciationScore: Double
    let feedback: FeedbackComment
    let aiCorrections: [ReviewLog]

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case questionText
        case userAnswer
        case overallScore
        case fluencyScore
        case vocabularyScore
        case grammarScore
        case pronunciationScore
        case feedback
        case aiCorrections
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        questionText: String,
        userAnswer: String,
        overallScore: Double,
        fluencyScore: Double,
        vocabularyScore: Double,
        grammarScore: Double,
        pronunciationScore: Double,
        feedback: FeedbackComment,
        aiCorrections: [ReviewLog]
    ) {
        self.id = id
        self.date = date
        self.questionText = questionText
        self.userAnswer = userAnswer
        self.overallScore = overallScore
        self.fluencyScore = fluencyScore
        self.vocabularyScore = vocabularyScore
        self.grammarScore = grammarScore
        self.pronunciationScore = pronunciationScore
        self.feedback = feedback
        self.aiCorrections = aiCorrections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        questionText = try container.decode(String.self, forKey: .questionText)
        userAnswer = try container.decode(String.self, forKey: .userAnswer)
        overallScore = try container.decode(Double.self, forKey: .overallScore)
        fluencyScore = try container.decode(Double.self, forKey: .fluencyScore)
        vocabularyScore = try container.decode(Double.self, forKey: .vocabularyScore)
        grammarScore = try container.decode(Double.self, forKey: .grammarScore)
        pronunciationScore = try container.decode(Double.self, forKey: .pronunciationScore)
        feedback = try container.decode(FeedbackComment.self, forKey: .feedback)
        aiCorrections = try container.decode([ReviewLog].self, forKey: .aiCorrections)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(questionText, forKey: .questionText)
        try container.encode(userAnswer, forKey: .userAnswer)
        try container.encode(overallScore, forKey: .overallScore)
        try container.encode(fluencyScore, forKey: .fluencyScore)
        try container.encode(vocabularyScore, forKey: .vocabularyScore)
        try container.encode(grammarScore, forKey: .grammarScore)
        try container.encode(pronunciationScore, forKey: .pronunciationScore)
        try container.encode(feedback, forKey: .feedback)
        try container.encode(aiCorrections, forKey: .aiCorrections)
    }
}


extension AIFeedback {
    static let mock = AIFeedback(
        questionText: "Describe your hometown.",
        userAnswer: "My hometown is very beautiful",
        overallScore: 7.5,
        fluencyScore: 7.0,
        vocabularyScore: 7.5,
        grammarScore: 7.0,
        pronunciationScore: 8.0,
        feedback: FeedbackComment(
            strengths: ["Clear basic description."],
            weaknesses: ["Lacks detail.", "No complex structures used."],
            ideaSuggestion: ["Add examples.", "Include sensory details."]
        ),
        aiCorrections: [
            ReviewLog(
                id: UUID(),
                type: .grammar,
                original: "Mock) My hometown is very beautiful",
                corrected: "My hometown is very beautiful.",
                explanation: "Add a full stop at the end of the sentence.",
                
            ),
            ReviewLog(
                id: UUID(),
                type: .vocabulary,
                original: "Mock) My hometown is very beautiful",
                corrected: "My hometown is very beautiful.",
                explanation: "Add a full stop at the end of the sentence.",
                
            )
        ]
    )
}
