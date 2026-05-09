//
//  OnboardingFlowView.swift
//  IELTSBuddy
//
//  Wraps Welcome → ProfileSetup using one shared `OnboardingViewModel`.
//

import SwiftUI

struct OnboardingFlowView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private enum Step {
        case welcome
        case profile
    }

    @State private var step: Step = .welcome

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView {
                    step = .profile
                }
            case .profile:
                ProfileSetupView(
                    viewModel: viewModel,
                    onCancel: { step = .welcome },
                    onFinished: {}
                )
            }
        }
    }
}

#Preview {
    OnboardingFlowView(viewModel: OnboardingViewModel())
}
