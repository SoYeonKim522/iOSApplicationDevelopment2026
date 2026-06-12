//
//  Color+Extensions.swift
//  IELTSBuddy
//

import SwiftUI

extension Color {
    // MARK: - Brand & surfaces

    /// Accent / interactive emphasis (`AccentColor` asset).
    static let appPrimary = Color("AccentColor")

    /// Standard card background (`SurfaceColor` asset).
    static let appSurface = Color("SurfaceColor")

    /// Secondary card / tinted panel (`SecondarySurface` asset).
    static let appSecondarySurface = Color("SecondarySurface")
    
    /// Secondary card border (`SecondarySurfaceBorder` asset).
    static let appSecondarySurfaceBorder = Color("SecondarySurfaceBorder")

    /// Root screen background (`BackgroundColor` asset).
    static let appBackground = Color("BackgroundColor")

    // MARK: - Typography

    /// Primary body and headline text (`TextPrimary` asset).
    static let appTextPrimary = Color("TextPrimary")

    /// Labels, captions, and supporting copy (`TextSecondary` asset).
    static let appTextSecondary = Color("TextSecondary")

    // MARK: - Nested UI

    /// Inset field areas inside cards, e.g. transcript box (`InnerField` asset).
    static let appInnerField = Color("InnerField")
}
