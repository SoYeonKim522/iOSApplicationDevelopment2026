//
//  HistoryView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI
import Combine

struct HistoryView: View {
    @StateObject var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.sessions.isEmpty {
                    VStack {
                        Text("No practice sessions yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Complete a practice session to see your history")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink(destination: HistoryDetailView(session: session)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(session.questionText)
                                        .font(.headline)
                                        .lineLimit(2)
                                    HStack {
                                        Text("Overall: \(session.overallScore, specifier: "%.1f")")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete(perform: viewModel.deleteSession)
                    }
                }
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.loadSessions()
            }
        }
    }
}

struct HistoryDetailView: View {
    let session: AIFeedback
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // question
                Text(session.questionText)
                    .font(.headline)
                    .padding(.top, 8)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(String(format: "%.1f", session.overallScore))
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                    Text("overall")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ],
                                    spacing: 12
                                ) {
                                    PillarScoreCell(title: "Fluency", score: session.fluencyScore)
                                    PillarScoreCell(title: "Vocabulary", score: session.vocabularyScore)
                                    PillarScoreCell(title: "Grammar", score: session.grammarScore)
                                    PillarScoreCell(title: "Pronunciation", score: session.pronunciationScore)
                                }
                
                VStack(alignment: .leading, spacing: 16) {
                                    Text("AI Analysis")
                                        .font(.title3.weight(.semibold))
                                    
                                    VStack(alignment: .leading, spacing: 14) {
                                        analysisBlock(title: "Idea Suggestion", items: session.feedback.ideaSuggestion)
                                        analysisBlock(title: "Strengths", items: session.feedback.strengths)
                                        analysisBlock(title: "Weaknesses", items: session.feedback.weaknesses)
                                        
                                        if !session.aiCorrections.isEmpty {
                                            Text("Key Corrections")
                                                .font(.headline.weight(.semibold))
                                                .padding(.top, 12)
                                            
                                            VStack(alignment: .leading, spacing: 10) {
                                                ForEach(session.aiCorrections) { log in
                                                    MistakeCard(
                                                        original: log.original,
                                                        corrected: log.corrected,
                                                        type: log.type,
                                                        explanation: log.explanation,
                                                        isBookmarked: bookmarkViewModel.isBookmarked(log.id),
                                                        onBookmarkTap: {
                                                            if bookmarkViewModel.isBookmarked(log.id) {
                                                                bookmarkViewModel.removeBookmark(id: log.id)
                                                            } else {
                                                                bookmarkViewModel.addBookmark(from: log, sessionId: session.id)
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                    )
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("Session Detail")
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear {
                            bookmarkViewModel.loadBookmarks()
                        }
                    }
                    
                    private func analysisBlock(title: String, items: [String]) -> some View {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(items, id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    
                    private func mistakeSubCard(_ log: ReviewLog) -> some View {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(log.type.rawValue.capitalized)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.primary.opacity(0.06)))
                            
                            Text(log.original)
                                .font(.subheadline)
                                .foregroundStyle(Color.red.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(log.corrected)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.green.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if !log.explanation.isEmpty {
                                Text(log.explanation)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }

                #Preview {
                    NavigationStack {
                        HistoryDetailView(session: AIFeedback.mock)
                    }
                }
#Preview {
    HistoryView()
}
