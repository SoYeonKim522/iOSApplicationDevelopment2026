//
//  WelcomeView.swift
//  IELTSBuddy
//
//  Onboarding screen #1 — welcome
//  No persistence, calls onContinue when the learner proceeds.

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 140, height: 140)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 78)
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 8) {
                    Text("IELTS Buddy")
                        .font(.system(size: 34, weight: .bold))
                    Text("Practice IELTS Speaking with instant AI feedback.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: onContinue) {
                    Label("Let's Begin", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("No email or sign-up required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
