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
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                VStack(spacing: 8) {
                    Text("IELTS Buddy")
                        .font(.system(size: 34, weight: .bold))
                    Text("Practice IELTS Speaking with instant AI feedback")
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
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .font(.headline)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("No email or sign-up required")
                    .font(.subheadline)
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
