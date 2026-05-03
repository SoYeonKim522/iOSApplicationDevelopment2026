//
//  ValidationError.swift
//  IELTSBuddy
//
//  Conforming to LocalizedError lets the UI display friendly
//  messages without hard coding strings in the views.
//

import Foundation

enum ValidationError: LocalizedError, Equatable {
    case emptyName
    case nameTooLong(maximum: Int)
    case nameContainsInvalidCharacters
    case invalidDailyGoal

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Please enter your name."
        case .nameTooLong(let maximum):
            return "Name must be \(maximum) characters or fewer."
        case .nameContainsInvalidCharacters:
            return "Name can only contain letters, spaces, hyphens or apostrophes."
        case .invalidDailyGoal:
            return "Daily goal must be at least 1 practice."
        }
    }
}
