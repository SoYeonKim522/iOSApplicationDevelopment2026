//
//  ErrorType+Color.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 13/6/2026.
//

import SwiftUI

extension ErrorType {
    var typeColor: Color {
        switch self {
        case .grammar: return Color.green
        case .vocabulary: return Color.orange
        case .pronunciation: return Color.purple
        }
    }
}
