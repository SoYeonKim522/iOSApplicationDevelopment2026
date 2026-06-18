//
//  HistoryDetailView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 14/5/2026.
//

import SwiftUI

struct HistoryDetailView: View {
    let session: AIFeedback
    @ObservedObject private var bookmarkViewModel = BookmarkViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Text(session.questionText)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.top, 8)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", session.overallScore))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("overall")
                        .font(.body)
                        .foregroundColor(Color.appTextSecondary)
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
                        .foregroundStyle(Color.appTextPrimary)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        AnalysisBlock(title: "Idea Suggestion",
                                      items: session.feedback.ideaSuggestion,
                                      systemImage: "lightbulb",
                                      color: Color.appPrimary
                        )
                        AnalysisBlock(title: "Strengths",
                                      items: session.feedback.strengths,
                                      systemImage: "checkmark",
                                      color: Color.green
                        )
                        
                        AnalysisBlock(title: "Weaknesses",
                                      items: session.feedback.weaknesses,
                                      systemImage: "exclamationmark.triangle",
                                      color: Color.orange
                        )
                        
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
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appTextPrimary.opacity(0.06), lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(session: AIFeedback.mock)
    }
}

