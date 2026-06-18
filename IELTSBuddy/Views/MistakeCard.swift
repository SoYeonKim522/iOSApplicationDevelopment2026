//
//  MistakeCard.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 13/6/2026.
//

import SwiftUI

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
                    .foregroundColor(type.typeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(type.typeColor.opacity(0.1))
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appInnerField)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appTextPrimary.opacity(0.06), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.02),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}
