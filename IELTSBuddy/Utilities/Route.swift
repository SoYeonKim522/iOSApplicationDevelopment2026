//
//  Route.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 10/5/2026.
//

import Foundation

enum Route: Hashable {
    case recording
    case feedback(attemptId: UUID)
}
