//
//  AppSettingsView.swift
//  IELTSBuddy
//
//  Settings tab shell; keeps Review log reachable (replaces dedicated Review tab).
//

import SwiftUI
import UIKit

struct AppSettingsView: View {
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "—"
    }

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

                Section {
                    NavigationLink {
                        ReviewLogView()
                    } label: {
                        Label("Review mistakes", systemImage: "list.bullet")
                    }
                }

                Section {
                    Button {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Open System Settings", systemImage: "arrow.up.forward.square")
                    }
                    .buttonStyle(.borderless)
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    AppSettingsView()
}
