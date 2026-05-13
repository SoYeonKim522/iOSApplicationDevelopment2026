//
//  HistoryDetailView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 14/5/2026.
//

import SwiftUI

struct HistoryDetailView: View {
    let session: AIFeedback
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
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
                                // reuses MistakeCard from ReviewLogView for consistent bookmark UI
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
    
    // shared with FeedbackResultView for consistent AI analysis display
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
}

#Preview {
    NavigationStack {
        HistoryDetailView(session: AIFeedback.mock)
    }
}

