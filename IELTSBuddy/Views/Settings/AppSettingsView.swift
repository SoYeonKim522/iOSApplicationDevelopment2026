//
//  AppSettingsView.swift
//  IELTSBuddy
//
//  Settings tab shell; keeps Review log reachable (replaces dedicated Review tab).
//

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Color scheme", selection: $appearancePreferenceRaw) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Text(preference.menuTitle).tag(preference.rawValue)
                        }
                    }
                }

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
