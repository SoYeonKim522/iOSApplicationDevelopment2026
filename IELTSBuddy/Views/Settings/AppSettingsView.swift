//
//  AppSettingsView.swift
//  IELTSBuddy
//
//  Settings tab shell; keeps Review log reachable (replaces dedicated Review tab).
//

import SwiftUI

struct AppSettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ReviewLogView()
                } label: {
                    Label("Review mistakes", systemImage: "list.bullet")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    AppSettingsView()
}
