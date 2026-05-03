//
//  TargetScore.swift
//  IELTSBuddy
//  Discrete IELTS band scores a learner can target.
//

import Foundation

enum TargetScore: Double, CaseIterable, Codable, Identifiable, Hashable {
    case fiveZero = 5.0
    case fiveFive = 5.5
    case sixZero = 6.0
    case sixFive = 6.5
    case sevenZero = 7.0
    case sevenFive = 7.5
    case eightZero = 8.0
    case eightFive = 8.5
    case nineZero = 9.0

    var id: Double {
        rawValue
    }

    var displayName: String {
        String(format: "Band %.1f", rawValue)
    }

    var shortLabel: String {
        String(format: "%.1f", rawValue)
    }

    // Suggested daily practice count to realistically reach this band.
    // Pure data so it can be tweaked without touching UI code.
    var suggestedDailyGoal: Int {
        switch self {
        case .fiveZero, .fiveFive: return 2
        case .sixZero, .sixFive: return 3
        case .sevenZero, .sevenFive: return 4
        case .eightZero, .eightFive, .nineZero: return 5
        }
    }
}
