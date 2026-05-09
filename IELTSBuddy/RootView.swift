//
//  RootView.swift
//  IELTSBuddy
//
//  Onboarding first; after profile exists, show main tabs.
//

import SwiftUI

struct RootView: View {
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue

    @StateObject private var onboardingViewModel = OnboardingViewModel()

    private var preferredColorScheme: ColorScheme? {
        AppearancePreference(rawValue: appearancePreferenceRaw)?.resolvedColorScheme
    }

    var body: some View {
        Group {
            if onboardingViewModel.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(onboardingViewModel)
            } else {
                OnboardingFlowView(viewModel: onboardingViewModel)
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    RootView()
}
