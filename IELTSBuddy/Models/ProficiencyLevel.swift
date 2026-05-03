
//  ProficiencyLevel.swift
//  IELTSBuddy
//
//

import Foundation

enum ProficiencyLevel: Int, CaseIterable, Codable, Identifiable, Hashable, Comparable {
    case beginner = 0
    case elementary = 1
    case intermediate = 2
    case upperIntermediate = 3
    case advanced = 4

    var id: Int {
        rawValue
    }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .elementary: return "Elementary"
        case .intermediate: return "Intermediate"
        case .upperIntermediate: return "Upper Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var cefrCode: String {
        switch self {
        case .beginner: return "A1"
        case .elementary: return "A2"
        case .intermediate: return "B1"
        case .upperIntermediate: return "B2"
        case .advanced: return "C1+"
        }
    }

    var summary: String {
        "\(displayName) · \(cefrCode)"
    }

    static func < (lhs: ProficiencyLevel, rhs: ProficiencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // Safe constructor from a slider value. Out-of-range input is
    // clamped to the nearest valid case rather than crashing.
    static func from(sliderValue value: Double) -> ProficiencyLevel {
        let rounded = Int(value.rounded())
        let clamped = min(max(rounded, Self.allCases.first!.rawValue),
                          Self.allCases.last!.rawValue)
        return ProficiencyLevel(rawValue: clamped) ?? .intermediate
    }
}
