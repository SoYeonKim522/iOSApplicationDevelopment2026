//
//  HistoryView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // question
                Text(session.questionText)
                    .font(.headline)
                    .padding()
                
                // scores
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scores")
                        .font(.title2)
                        .bold()
                    Text("Overall: \(session.overallScore, specifier: "%.1f")")
                    Text("Fluency: \(session.fluencyScore, specifier: "%.1f")")
                    Text("Vocabulary: \(session.vocabularyScore, specifier: "%.1f")")
                    Text("Grammar: \(session.grammarScore, specifier: "%.1f")")
                    Text("Pronunciation: \(session.pronunciationScore, specifier: "%.1f")")
                }
                .padding()
                
                // feedback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback")
                        .font(.title2)
                        .bold()
                    Text("Strengths: \(session.feedback.strengths)")
                    Text("Weaknesses: \(session.feedback.weaknesses)")
                    Text("Suggestion: \(session.feedback.ideaSuggestion)")
                }
                .padding()
                
                // mistakes
                if !session.reviewLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Corrections")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ForEach(session.reviewLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Original: \(log.original)")
                                    .font(.subheadline)
                                Text("Corrected: \(log.corrected)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                if !log.explanation.isEmpty {
                                    Text(log.explanation)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    let vm = HistoryViewModel()
    vm.sessions = [AIFeedback.mock]
    HistoryView(viewModel: vm)
}
