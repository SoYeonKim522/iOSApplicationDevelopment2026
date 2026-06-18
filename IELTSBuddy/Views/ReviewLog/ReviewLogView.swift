//
//  ReviewLogView.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 7/5/2026.
//

import SwiftUI

struct ReviewLogView: View {
    @StateObject var viewModel: ReviewLogViewModel
    @ObservedObject var bookmarkViewModel = BookmarkViewModel.shared
    @State private var selectedSegment = 0
    @State private var showingError = false
    
    init(
        viewModel: ReviewLogViewModel = ReviewLogViewModel()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pickerView
                contentView
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

    private var pickerView: some View {
        Picker("", selection: $selectedSegment) {
            Text("All Mistakes").tag(0)
            Text("Saved").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var contentView: some View {
        Group {
            if selectedSegment == 1 {
                savedView
            } else {
                allMistakesView
            }
        }
    }

    private var savedView: some View {
        Group {
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
        }
    }

    private var allMistakesView: some View {
        Group {
            filterScrollView
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

    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(
                    type: nil,
                    count: viewModel.totalMistakes,
                    isSelected: viewModel.selectedFilter == nil
                ) {
                    viewModel.filterBy(nil)
                }
                ForEach(ErrorType.allCases, id: \.self) { type in
                    FilterButton(
                        type: type,
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

#Preview {
    let reviewVM = ReviewLogViewModel()
    reviewVM.loadMistakes(from: [AIFeedback.mock])
    return ReviewLogView(viewModel: reviewVM)
}
