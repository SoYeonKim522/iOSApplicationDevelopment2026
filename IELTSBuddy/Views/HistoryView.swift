//
//  HistoryView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel = HistoryViewModel()
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.sessions.isEmpty {
                    VStack {
                        Text("No practice sessions yet")
                            .font(.headline)
                            .foregroundColor(Color.appTextPrimary)
                        Text("Complete a practice session to see your history")
                            .font(.subheadline)
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.sessions.sorted(by: { $0.date > $1.date }), id: \.id) { session in
                            NavigationLink(destination: HistoryDetailView(session: session)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(session.questionText)
                                        .font(.headline)
                                        .foregroundColor(Color.appTextPrimary)
                                        .lineLimit(2)
                                    HStack {
                                        Text("Overall: \(session.overallScore, specifier: "%.1f")")
                                            .font(.subheadline)
                                            .foregroundColor(Color.appPrimary)
                                        Spacer()
                                    }
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(Color.appTextSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete { offsets in
                            offsets
                                .map { viewModel.sortedSessions[$0] }
                                .forEach { viewModel.deleteSession($0) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("History")
            .onAppear {
                viewModel.loadSessions()
            }
            .alert("Something went wrong", isPresented: $showingError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                    showingError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "Please try again.")
            }
            .onChange(of: viewModel.errorMessage) {
                if viewModel.errorMessage != nil {
                    showingError = true
                }
            }
        }
    }
}
#Preview {
    HistoryView()
}


