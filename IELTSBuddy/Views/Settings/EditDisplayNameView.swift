//
//  EditDisplayNameView.swift
//  IELTSBuddy
//
//  Change display name; uses `UserProfile.updating` via OnboardingViewModel.
//

import SwiftUI

struct EditDisplayNameView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""

    private var trimmedNameCount: Int {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var nameFieldError: String? {
        guard let error = onboardingViewModel.validationError else { return nil }
        switch error {
        case .emptyName, .nameTooLong, .nameContainsInvalidCharacters:
            return error.errorDescription
        case .invalidDailyGoal:
            return nil
        }
    }

    var body: some View {
        Form {
            Section {
                TextField("Your name", text: $draftName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onChange(of: draftName) { _, _ in
                        onboardingViewModel.clearValidationError()
                    }

                if let nameFieldError {
                    Text(nameFieldError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("\(trimmedNameCount)/\(UserProfile.maxNameLength)")
                        .font(.caption2)
                        .foregroundStyle(Color.appTextSecondary)
                }
            } footer: {
                Text("Letters, spaces, hyphens and apostrophes only.")
                    .foregroundStyle(Color.appTextSecondary)
            }

            if let message = onboardingViewModel.errorMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Display name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    if onboardingViewModel.updateDisplayName(draftName) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            draftName = onboardingViewModel.savedProfile?.name ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        EditDisplayNameView()
            .environmentObject(OnboardingViewModel())
    }
}
