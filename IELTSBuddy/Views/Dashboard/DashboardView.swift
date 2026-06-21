//
//  DashboardView.swift
//  IELTSBuddy
//
//  Home hub layout: greeting, daily goal card, stats, practice CTA, recommended topics row.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var recordingViewModel = RecordingViewModel()
    @State private var path = NavigationPath()
    
    let services: AppServices

    init(services: AppServices) {
        self.services = services
        _recordingViewModel = StateObject(wrappedValue: RecordingViewModel(
            manager: services.speechManager,
            questionGenerator: services.questionGenerator
        ))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = onboardingViewModel.savedProfile {
                        greetingBlock(profile: profile)
                            .padding(.top, 8)
                        
                        dailyGoalCard(profile: profile)
                        statsRow
                        startPracticeButton
                        recommendedTopicsSection
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
                case .feedback(let attemptId):
                    if let attempt = AttemptMediaStore.shared.attempt(for: attemptId) {
                        FeedbackResultView(
                            attempt: attempt,
                            services: services,
                            onExitToRoot: {
                                AttemptMediaStore.shared.remove(id: attemptId)
                                recordingViewModel.resetForNextQuestion()
                                path = NavigationPath()
                            },
                            onNextQuestion: {
                                AttemptMediaStore.shared.remove(id: attemptId)
                                recordingViewModel.resetForNextQuestion()
                                path.removeLast()
                            }
                        )
                    } else {
                        ContentUnavailableView(
                            "Practice session not found",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Start a new recording and try again.")
                        )
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("IELTS Buddy")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            onboardingViewModel.loadSavedProfile()
            dashboardViewModel.refreshStats()
        }
    }

    private func greetingBlock(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // main title
            Text("\(timeGreeting()), \(greetingName(profile.name))!")
                .font(.title2.bold())
                .foregroundStyle(Color.appTextPrimary)
            
            // sub title (date)
            Text(Date(), format: .dateTime.weekday(.wide).day().month(.abbreviated))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
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
                .foregroundStyle(Color.appTextPrimary)

            HStack(alignment: .center, spacing: 14) {
                DailyGoalRing(progress: progress, done: done, goal: goal)
                    .padding(.vertical, 4)

                Rectangle()
                    .fill(Color.appTextSecondary.opacity(0.28))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        Text("\(profile.currentLevel.displayName) (\(profile.currentLevel.cefrCode))")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Target")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        Text(profile.targetScore.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appSecondarySurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appSecondarySurfaceBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.06),
            radius: 10, x: 0,y: 4
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                title: "Total Practices",
                value: "\(dashboardViewModel.sessionCount)",
                systemImage: "checkmark.seal"
            )
            statTile(
                title: "This Week",
                value: "\(dashboardViewModel.weeklyPracticeCount)",
                systemImage: "clock",
                iconColor: .green
            )
        }
    }

    private func statTile(title: String, value: String, systemImage: String, iconColor: Color = .appPrimary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.appPrimary.opacity(0.12)))
                
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color.appTextPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface)
        )
        .shadow(
            color: Color.black.opacity(0.03),
            radius: 10, x: 0,y: 4
        )
    }

    private var startPracticeButton: some View {
        Button {
                path.append(Route.recording)
            } label: {
                Label("Start New Practice", systemImage: "mic")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            .tint(Color.appPrimary)
            .controlSize(.large)
    }

    private var recommendedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended topics")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                
                Button {
                    dashboardViewModel.refreshRecommendedTopics()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dashboardViewModel.recommendedTopicItems) { item in
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

            Text("Tap a topic to open practice with Part 1")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
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


#Preview {
    struct PreviewHolder: View {
        @StateObject private var vm = OnboardingViewModel()
        var body: some View {
            DashboardView(services: .preview)
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
