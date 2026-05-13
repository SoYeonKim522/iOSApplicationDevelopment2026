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
    @StateObject private var recordingViewModel = RecordingViewModel()
    @State private var path = NavigationPath()
    
    // Switch main TabView to Practice (tag 1).
    var goToPractice: () -> Void = {}

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = onboardingViewModel.savedProfile {
                        greetingBlock(profile: profile)
                        dailyGoalCard(profile: profile)
                        statsRow
                        startPracticeButton
                        weeklyRecommendedTopicsSection
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .recording:
                    RecordingView(
                            viewModel: recordingViewModel,
                            onNavigate: { route in path.append(route) }
                        )
                case .feedback(let question, let transcript, let url):
                    FeedbackResultView(
                        questionText: question,
                        transcript: transcript,
                        audioFileURL: url,
                        onExitToRoot: {
                            path = NavigationPath()
                        },
                        onNextQuestion: {
                            recordingViewModel.resetForNextQuestion()
                            path.removeLast()
                        }
                    )
                }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("\(timeGreeting()), \(greetingName(profile.name))!")
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dailyGoalCard(profile: UserProfile) -> some View {
        let goal = max(profile.dailyGoal, 1)
        let done = dashboardViewModel.practicesToday
        let progress = min(1, Double(done) / Double(goal))

        return VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goal")
                .font(.headline)

            HStack(alignment: .center, spacing: 14) {
                DailyGoalRing(progress: progress, done: done, goal: goal)
                    .padding(.vertical, 4)

                Rectangle()
                    .fill(Color.secondary.opacity(0.28))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        Text("\(profile.currentLevel.displayName) (\(profile.currentLevel.cefrCode))")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        Text(profile.targetScore.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        Button {
                path.append(Route.recording) 
            } label: {
                Label("Start New Practice", systemImage: "mic.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }

    private var weeklyRecommendedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly hot topics")
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
                        Button {
                            recordingViewModel.preparePracticeEntry(
                                topic: item.topicCategory,
                                part: item.part
                            )
                            path.append(Route.recording)
                        } label: {
                            RecommendedTopicCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.topicTitle), \(item.partLabel)")
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

    // First word of the stored name for a natural headline ("David Lee" will be "David"; empty will be "there")
    private func greetingName(_ fullName: String) -> String {
        let t = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "there" }
        let parts = t.split(separator: " ", omittingEmptySubsequences: true)
        if let first = parts.first {
            return String(first)
        }
        return t
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

private struct RecommendedTopicCard: View {
    let item: UpcomingQuestionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.emoji)
                .font(.title)
            Text(item.topicTitle)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(item.partLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
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
