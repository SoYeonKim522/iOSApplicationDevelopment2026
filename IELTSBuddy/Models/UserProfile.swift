//
//  UserProfile.swift
//  IELTSBuddy
//
//

import Foundation

struct UserProfile: Codable, Equatable, Identifiable {
    static let maxNameLength = 30

    let id: UUID
    let name: String
    let targetScore: TargetScore
    let currentLevel: ProficiencyLevel
    let dailyGoal: Int
    let createdAt: Date

    // Validating
    // from raw, untrusted input.
    static func make(
        name rawName: String,
        targetScore: TargetScore,
        currentLevel: ProficiencyLevel,
        dailyGoal: Int? = nil,
        now: Date = Date(),
        id: UUID = UUID()
    ) -> Result<UserProfile, ValidationError> {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.emptyName)
        }
        guard trimmed.count <= maxNameLength else {
            return .failure(.nameTooLong(maximum: maxNameLength))
        }
        guard trimmed.allSatisfy(Self.isAllowedNameCharacter) else {
            return .failure(.nameContainsInvalidCharacters)
        }

        let goal = dailyGoal ?? targetScore.suggestedDailyGoal
        guard goal >= 1 else {
            return .failure(.invalidDailyGoal)
        }

        return .success(UserProfile(
            id: id,
            name: trimmed,
            targetScore: targetScore,
            currentLevel: currentLevel,
            dailyGoal: goal,
            createdAt: now
        ))
    }

    // Returns a new profile with the given fields changed.
    func updating(
        name: String? = nil,
        targetScore: TargetScore? = nil,
        currentLevel: ProficiencyLevel? = nil,
        dailyGoal: Int? = nil
    ) -> Result<UserProfile, ValidationError> {
        UserProfile.make(
            name: name ?? self.name,
            targetScore: targetScore ?? self.targetScore,
            currentLevel: currentLevel ?? self.currentLevel,
            dailyGoal: dailyGoal ?? self.dailyGoal,
            now: self.createdAt,
            id: self.id
        )
    }

    private static func isAllowedNameCharacter(_ ch: Character) -> Bool {
        ch.isLetter || ch.isWhitespace || ch == "-" || ch == "'"
    }
}
