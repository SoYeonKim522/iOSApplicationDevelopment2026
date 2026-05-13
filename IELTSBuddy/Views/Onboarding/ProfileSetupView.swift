//
//  ProfileSetupView.swift
//  IELTSBuddy
//
//  Onboarding screen #2 — name, target band, and level.
//  Uses OnboardingViewModel for validation and persistence (no AppSession).
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onCancel: () -> Void
    let onFinished: () -> Void

    private var trimmedNameCount: Int {
        viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSubmit: Bool {
        trimmedNameCount > 0
    }

    private var nameFieldError: String? {
        guard let error = viewModel.validationError else { return nil }
        switch error {
        case .emptyName, .nameTooLong, .nameContainsInvalidCharacters:
            return error.errorDescription
        case .invalidDailyGoal:
            return nil
        }
    }

    private var generalValidationError: String? {
        guard let error = viewModel.validationError else { return nil }
        if case .invalidDailyGoal = error {
            return error.errorDescription
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("This helps us tailor your daily practice. You can change it any time later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    nameSection
                    targetScoreSection
                    currentLevelSection

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let message = generalValidationError {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Button {
                        viewModel.saveProfile()
                        if viewModel.savedProfile != nil {
                            onFinished()
                        }
                    } label: {
                        Label("Finish Setup", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                            .foregroundStyle(.white)
                            .font(.headline)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canSubmit)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", action: onCancel)
                }
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Name")
               
            TextField("Your name", text: $viewModel.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: viewModel.name) { _, _ in
                    viewModel.clearValidationError()
                }

            if let nameFieldError {
                Text(nameFieldError)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("\(trimmedNameCount)/\(UserProfile.maxNameLength)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var targetScoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Target Score")
            Picker("Target Score", selection: $viewModel.selectedTarget) {
                ForEach(TargetScore.allCases) { score in
                    Text(score.displayName).tag(score)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )

            Text("Suggested daily goal: \(viewModel.selectedTarget.suggestedDailyGoal) practices")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var currentLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Current Level")
                Spacer()
                Text(viewModel.selectedLevel.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(viewModel.selectedLevel.rawValue) },
                    set: { viewModel.selectedLevel = ProficiencyLevel.from(sliderValue: $0) }
                ),
                in: Double(ProficiencyLevel.allCases.first!.rawValue)
                    ... Double(ProficiencyLevel.allCases.last!.rawValue),
                step: 1
            )

            HStack {
                Text(ProficiencyLevel.allCases.first!.cefrCode)
                Spacer()
                Text(ProficiencyLevel.allCases.last!.cefrCode)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel = OnboardingViewModel()
        var body: some View {
            ProfileSetupView(viewModel: viewModel, onCancel: {}, onFinished: {})
        }
    }
    return PreviewWrapper()
}
