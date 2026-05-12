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
    @StateObject var bookmarkViewModel = BookmarkViewModel()
    @State private var selectedSegment = 0
    
    init(
            viewModel: ReviewLogViewModel = ReviewLogViewModel(),
            bookmarkViewModel: BookmarkViewModel = BookmarkViewModel()
        ) {
            _viewModel = StateObject(wrappedValue: viewModel)
            _bookmarkViewModel = StateObject(wrappedValue: bookmarkViewModel)
        }
    
    var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    
                    // segmented control
                    Picker("", selection: $selectedSegment) {
                        Text("All Mistakes").tag(0)
                        Text("Saved").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    if selectedSegment == 1 {
                        // saved view
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
                        // all mistakes view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterButton(
                                    title: "All",
                                    count: viewModel.totalMistakes,
                                    isSelected: viewModel.selectedFilter == nil
                                ) {
                                    viewModel.filterBy(nil)
                                }
                                FilterButton(
                                    title: "Grammar",
                                    count: viewModel.grammarCount,
                                    isSelected: viewModel.selectedFilter == .grammar
                                ) {
                                    viewModel.filterBy(.grammar)
                                }
                                FilterButton(
                                    title: "Vocabulary",
                                    count: viewModel.vocabularyCount,
                                    isSelected: viewModel.selectedFilter == .vocabulary
                                ) {
                                    viewModel.filterBy(.vocabulary)
                                }
                                FilterButton(
                                    title: "Pronunciation",
                                    count: viewModel.pronunciationCount,
                                    isSelected: viewModel.selectedFilter == .pronunciation
                                ) {
                                    viewModel.filterBy(.pronunciation)
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
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Review Log")
                .onAppear {
                    let historyVM = HistoryViewModel()
                    historyVM.loadSessions()
                    viewModel.loadMistakes(from: historyVM.sessions)
                    bookmarkViewModel.loadBookmarks()
                }
            }
        }
                   private func emptyState(message: String, subtitle: String) -> some View {
                       VStack(spacing: 8) {
                           Spacer()
                           Image(systemName: "checkmark.circle.fill")
                               .font(.system(size: 44))
                               .foregroundColor(.blue.opacity(0.3))
                           Text(message)
                               .font(.headline)
                               .foregroundColor(.gray)
                           Text(subtitle)
                               .font(.subheadline)
                               .foregroundColor(.gray.opacity(0.7))
                               .multilineTextAlignment(.center)
                               .padding(.horizontal)
                           Spacer()
                       }
                   }
               }

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
                                   .foregroundColor(isBookmarked ? .blue : .gray)
                               }
                               .buttonStyle(.plain)
                           }
                           
                           VStack(alignment: .leading, spacing: 4) {
                               Text("Original")
                                   .font(.caption)
                                   .foregroundColor(.gray)
                               Text(original)
                                   .font(.subheadline)
                                   .foregroundColor(.red.opacity(0.85))
                           }
                           
                           Divider()
                           
                           VStack(alignment: .leading, spacing: 4) {
                               Text("Corrected")
                                   .font(.caption)
                                   .foregroundColor(.gray)
                               Text(corrected)
                                   .font(.subheadline)
                                   .foregroundColor(.blue)
                           }
                           
                           if !explanation.isEmpty {
                               VStack(alignment: .leading, spacing: 4) {
                                   Text("Why")
                                       .font(.caption)
                                       .foregroundColor(.gray)
                                   Text(explanation)
                                       .font(.caption)
                                       .foregroundColor(.secondary)
                               }
                           }
                       }
                       .padding()
                       .background(Color.white)
                       .cornerRadius(16)
                   }
                   
                   var typeColor: Color {
                       switch type {
                       case .grammar: return .blue
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
                                   .background(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.1))
                                   .foregroundColor(isSelected ? .white : .blue)
                                   .cornerRadius(10)
                           }
                           .font(.subheadline)
                           .padding(.horizontal, 16)
                           .padding(.vertical, 8)
                           .background(isSelected ? Color.blue : Color.white)
                           .foregroundColor(isSelected ? .white : .primary)
                           .cornerRadius(20)
                           .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                       }
                   }
               }

#Preview {
    let reviewVM = ReviewLogViewModel()
    let bookmarkVM = BookmarkViewModel()
    reviewVM.loadMistakes(from: [AIFeedback.mock])
    return ReviewLogView(viewModel: reviewVM, bookmarkViewModel: bookmarkVM)
}
