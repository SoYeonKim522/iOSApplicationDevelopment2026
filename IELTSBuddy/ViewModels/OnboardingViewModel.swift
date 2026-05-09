//
//  OnboardingViewModel.swift
//  IELTSBuddy
//
//  Draft state + validation for onboarding screens 1 & 2.
//
//  Practice session history uses savedSessions from HistoryViewModel; not written here
//

import Combine
import Foundation
import SwiftUI

final class OnboardingViewModel: ObservableObject {

    // Must match reads elsewhere if you load UserProfile outside this type.
    static let profileStorageKey = "savedUserProfile"

    @Published var name: String = ""
    @Published var selectedLevel: ProficiencyLevel = .intermediate
    @Published var selectedTarget: TargetScore = .sixZero
    
    // When nil, UserProfile.make uses targetScore.suggestedDailyGoal.
    @Published var dailyGoalOverride: Int?

    @Published private(set) var savedProfile: UserProfile?
    @Published var validationError: ValidationError?
    @Published var errorMessage: String?

    private let storageKey = OnboardingViewModel.profileStorageKey

    init() {
        loadSavedProfile()
    }

    var hasCompletedOnboarding: Bool {
        savedProfile != nil
    }

    // Call after app launch or when refreshing profile from disk.
    func loadSavedProfile() {
        errorMessage = nil
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            savedProfile = nil
            return
        }
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            savedProfile = profile
            applyDraft(from: profile)
        } catch {
            print("Failed to load user profile: \(error)")
            errorMessage = "Could not load your profile. Please try again."
            savedProfile = nil
        }
    }

    // Validates draft fields and saves on success.
    func saveProfile() {
        validationError = nil
        errorMessage = nil
        switch UserProfile.make(
            name: name,
            targetScore: selectedTarget,
            currentLevel: selectedLevel,
            dailyGoal: dailyGoalOverride
        ) {
        case .success(let profile):
            persist(profile)
            savedProfile = profile
        case .failure(let error):
            validationError = error
        }
    }

    func clearValidationError() {
        validationError = nil
    }

    // Removes persisted profile (reset onboarding in debug)
    func clearPersistedProfile() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        savedProfile = nil
    }

    private func applyDraft(from profile: UserProfile) {
        name = profile.name
        selectedLevel = profile.currentLevel
        selectedTarget = profile.targetScore
        let suggested = profile.targetScore.suggestedDailyGoal
        dailyGoalOverride = profile.dailyGoal == suggested ? nil : profile.dailyGoal
    }

    private func persist(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save user profile: \(error)")
            errorMessage = "Something went wrong saving your profile. Please try again."
        }
    }
}
