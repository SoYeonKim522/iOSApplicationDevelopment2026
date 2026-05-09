//
//  RootView.swift
//  IELTSBuddy
//
//  Onboarding first; after profile exists, show main tabs.
//

import SwiftUI

struct RootView: View {
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some View {
        Group {
            if onboardingViewModel.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(onboardingViewModel)
            } else {
                OnboardingFlowView(viewModel: onboardingViewModel)
            }
        }
    }
}

#Preview {
    RootView()
}
