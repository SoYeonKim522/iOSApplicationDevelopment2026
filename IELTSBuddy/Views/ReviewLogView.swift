//
//  ReviewLogView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI
import Combine

struct ReviewLogView: View {
    @StateObject var viewModel = ReviewLogViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // counts
                HStack(spacing: 12) {
                    CountBadge(count: viewModel.grammarCount, label: "Grammar", color: .blue)
                    CountBadge(count: viewModel.vocabularyCount, label: "Vocab", color: .orange)
                    CountBadge(count: viewModel.pronunciationCount, label: "Pronun", color: .purple)
                }
                .padding()
                
                // filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterButton(title: "All", isSelected: viewModel.selectedFilter == nil) {
                            viewModel.filterBy(nil)
                        }
                        FilterButton(title: "Grammar", isSelected: viewModel.selectedFilter == .grammar) {
                            viewModel.filterBy(.grammar)
                        }
                        FilterButton(title: "Vocabulary", isSelected: viewModel.selectedFilter == .vocabulary) {
                            viewModel.filterBy(.vocabulary)
                        }
                        FilterButton(title: "Pronunciation", isSelected: viewModel.selectedFilter == .pronunciation) {
                            viewModel.filterBy(.pronunciation)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // mistakes list
                if viewModel.filteredMistakes.isEmpty {
                    Spacer()
                    Text("No mistakes found")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Spacer()
                } else {
                    List(viewModel.filteredMistakes) { mistake in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mistake.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Original")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(mistake.original)
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Corrected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(mistake.corrected)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            
                            if !mistake.explanation.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Explanation")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(mistake.explanation)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Review Log")
            .onAppear {
                viewModel.loadMistakes(from: [AIFeedback.mock])
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct CountBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ReviewLogView()
}
