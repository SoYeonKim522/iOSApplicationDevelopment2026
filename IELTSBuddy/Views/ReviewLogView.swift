//
//  ReviewLogView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI

struct ReviewLogView: View {
    @StateObject var viewModel = ReviewLogViewModel()
    @ObservedObject var bookmarkViewModel = BookmarkViewModel.shared
    @State private var selectedSegment = 0
    @State private var showingError = false
    
    init(
        viewModel: ReviewLogViewModel = ReviewLogViewModel(),
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // toggle between all mistakes and saved mistakes
                Picker("", selection: $selectedSegment) {
                    Text("All Mistakes").tag(0)
                    Text("Saved").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                if selectedSegment == 1 {
                    if bookmarkViewModel.bookmarks.isEmpty {
                        emptyState(
                            message: "No saved mistakes yet",
                            subtitle: "Tap the bookmark icon on any mistake to save it"
                        )
                    } else {
                        List(bookmarkViewModel.bookmarks) { bookmark in
                            MistakeCard(
                                original: bookmark.original,
                                corrected: bookmark.corrected,
                                type: bookmark.type,
                                explanation: bookmark.explanation,
                                isBookmarked: true,
                                onBookmarkTap: {
                                    bookmarkViewModel.removeBookmark(id: bookmark.id)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterButton(
                                        title: "All",
                                        count: viewModel.totalMistakes,
                                        isSelected: viewModel.selectedFilter == nil
                                    ) {
                                        viewModel.filterBy(nil)
                                    }
                            ForEach(ErrorType.allCases, id: \.self) { type in
                                        FilterButton(
                                            title: type.rawValue.capitalized,
                                            count: viewModel.count(for: type),
                                            isSelected: viewModel.selectedFilter == type
                                        ) {
                                            viewModel.filterBy(type)
                                        }
                                    }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    if viewModel.filteredMistakes.isEmpty {
                        emptyState(
                            message: "No mistakes found",
                            subtitle: "Keep practicing to see corrections"
                        )
                    } else {
                        List(viewModel.filteredMistakes) { mistake in
                            MistakeCard(
                                original: mistake.original,
                                corrected: mistake.corrected,
                                type: mistake.type,
                                explanation: mistake.explanation,
                                isBookmarked: bookmarkViewModel.isBookmarked(mistake.id),
                                onBookmarkTap: {
                                    if bookmarkViewModel.isBookmarked(mistake.id) {
                                        bookmarkViewModel.removeBookmark(id: mistake.id)
                                    } else {
                                        bookmarkViewModel.addBookmark(
                                            from: mistake,
                                            sessionId: UUID()
                                        )
                                    }
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Review Log")
            .onAppear {
                let historyVM = HistoryViewModel()
                historyVM.loadSessions()
                viewModel.loadMistakes(from: historyVM.sessions)
            }
            .alert("Something went wrong", isPresented: $showingError) {
                Button("OK") {
                    bookmarkViewModel.errorMessage = nil
                    showingError = false
                }
            } message: {
                Text(bookmarkViewModel.errorMessage ?? "Please try again.")
            }
            .onChange(of: bookmarkViewModel.errorMessage) {
                if bookmarkViewModel.errorMessage != nil {
                    showingError = true
                }
            }
        }
    }
    private func emptyState(message: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(Color.appPrimary.opacity(0.3))
            Text(message)
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
}
// reusable card for displaying a single mistake with bookmark support
struct MistakeCard: View {
    let original: String
    let corrected: String
    let type: ErrorType
    let explanation: String
    let isBookmarked: Bool
    let onBookmarkTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.1))
                    .cornerRadius(20)
                
                Spacer()
                
                Button(action: onBookmarkTap) {
                    HStack(spacing: 4) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14))
                        if isBookmarked {
                            Text("Saved")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(isBookmarked ? Color.appPrimary : Color.appTextSecondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(Color.appTextSecondary)
                Text(original)
                    .font(.subheadline)
                    .foregroundColor(.red.opacity(0.85))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Corrected")
                    .font(.caption)
                    .foregroundColor(Color.appTextSecondary)
                Text(corrected)
                    .font(.subheadline)
                    .foregroundColor(Color.appTextPrimary)
            }
            
            if !explanation.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why")
                        .font(.caption)
                        .foregroundColor(Color.appTextSecondary)
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(Color.appTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
    }
    
    var typeColor: Color {
        switch type {
        case .grammar: return Color.appPrimary
        case .vocabulary: return .orange
        case .pronunciation: return .purple
        }
    }
}

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.appPrimary.opacity(0.1))
                    .foregroundColor(isSelected ? .white : Color.appPrimary)
                    .cornerRadius(10)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appPrimary : Color.appSurface)
            .foregroundColor(isSelected ? .white : Color.appTextPrimary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    let reviewVM = ReviewLogViewModel()
    reviewVM.loadMistakes(from: [AIFeedback.mock])
    return ReviewLogView(viewModel: reviewVM)
}
