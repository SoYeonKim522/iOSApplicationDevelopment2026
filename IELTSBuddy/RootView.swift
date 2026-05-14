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
    
    let services: AppServices

    private var preferredColorScheme: ColorScheme? {
        AppearancePreference(rawValue: appearancePreferenceRaw)?.resolvedColorScheme
    }

    var body: some View {
        Group {
            if onboardingViewModel.hasCompletedOnboarding {
                ContentView(services: services)
                    .environmentObject(onboardingViewModel)
            } else {
                OnboardingFlowView(viewModel: onboardingViewModel)
            }
        }
    }
}

#Preview {
    RootView(services: .preview)
}
