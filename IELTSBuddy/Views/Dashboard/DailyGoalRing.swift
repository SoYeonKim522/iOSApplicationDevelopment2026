//
//  DailyGoalRing.swift
//  IELTSBuddy
//

import SwiftUI

struct DailyGoalRing: View {
    let progress: CGFloat
    let done: Int
    let goal: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appTextSecondary.opacity(0.22), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(done) / \(goal)")
                    .font(.title2.bold())
                    .foregroundStyle(Color.appTextPrimary)
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .frame(width: 128, height: 128)
        .accessibilityLabel("Daily goal \(done) of \(goal)")
    }
}
