//
//  DashboardView.swift
//  IELTSBuddy
//
//  Home hub layout aligned with design: greeting, daily ring, stats, CTA, upcoming row.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()

    /// Switch main `TabView` to Practice (tag 1).
    var goToPractice: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = onboardingViewModel.savedProfile {
                        greetingBlock(profile: profile)
                        dailyGoalCard(profile: profile)
                        statsRow
                        startPracticeButton
                        upcomingQuestionsSection
                    } else {
                        ContentUnavailableView(
                            "No profile yet",
                            systemImage: "person.crop.circle.badge.exclamationmark",
                            description: Text("Finish onboarding to see your dashboard.")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).opacity(0.55))
            .navigationTitle("IELTS Buddy")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            onboardingViewModel.loadSavedProfile()
            dashboardViewModel.refreshStats()
        }
    }

    private func greetingBlock(profile: UserProfile) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(timeGreeting()), \(nameMonogram(profile.name))!")
                    .font(.title2.bold())
                Text("Target: \(profile.targetScore.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(Color.accentColor)
                Text(profile.currentLevel.cefrCode)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
        }
    }

    private func dailyGoalCard(profile: UserProfile) -> some View {
        let goal = max(profile.dailyGoal, 1)
        let done = dashboardViewModel.practicesToday
        let progress = min(1, Double(done) / Double(goal))

        return VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goal")
                .font(.headline)

            HStack(spacing: 20) {
                DailyGoalRing(progress: progress, done: done, goal: goal)
                    .padding(.vertical, 4)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                title: "Total Practices",
                value: "\(dashboardViewModel.sessionCount)",
                systemImage: "checkmark.seal.fill"
            )
            statTile(
                title: "This Week",
                value: "\(dashboardViewModel.weeklyPracticeCount)",
                systemImage: "calendar"
            )
        }
    }

    private func statTile(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var startPracticeButton: some View {
        Button(action: goToPractice) {
            Label("Start New Practice", systemImage: "mic.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var upcomingQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Questions")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    dashboardViewModel.refreshUpcomingQuestions()
                }
                .font(.caption.weight(.semibold))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dashboardViewModel.upcomingItems) { item in
                        UpcomingQuestionCard(item: item)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func timeGreeting(date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func nameMonogram(_ name: String) -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let c = t.first else { return "there" }
        return String(c).uppercased()
    }
}

// MARK: - Pieces

private struct DailyGoalRing: View {
    let progress: CGFloat
    let done: Int
    let goal: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.22), lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(done) / \(goal)")
                    .font(.title2.bold())
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 128, height: 128)
        .accessibilityLabel("Daily goal \(done) of \(goal)")
    }
}

private struct UpcomingQuestionCard: View {
    let item: UpcomingQuestionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Q\(item.questionNumber)")
                .font(.title2.bold())
            Text(item.partLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.topicTitle)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 148, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    struct PreviewHolder: View {
        @StateObject private var vm = OnboardingViewModel()
        var body: some View {
            DashboardView(goToPractice: {})
                .environmentObject(vm)
                .onAppear {
                    if case .success(let p) = UserProfile.make(
                        name: "H",
                        targetScore: .sevenZero,
                        currentLevel: .upperIntermediate
                    ) {
                        vm.name = p.name
                        vm.selectedTarget = p.targetScore
                        vm.selectedLevel = p.currentLevel
                        vm.saveProfile()
                    }
                }
        }
    }
    return PreviewHolder()
}
