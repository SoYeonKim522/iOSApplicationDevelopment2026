//
//  FilterButton.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 13/6/2026.
//

import SwiftUI

struct FilterButton: View {
    let type: ErrorType?
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        if let type = type {
            return type.typeColor
        } else {
            return Color.appPrimary
        }
    }
        
    private var buttonTitle: String {
        if let type = type {
            return type.rawValue.capitalized
        } else {
            return "All"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(buttonTitle)
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : buttonColor.opacity(0.1))
                    .foregroundColor(isSelected ? .white : buttonColor)
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
