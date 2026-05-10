//
//  ContentView.swift
//  IELTSBuddy
//
//  Created by yosam on 3/5/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(goToPractice: { selectedTab = 0 })
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "play.rectangle.fill")
                }
                .tag(1)

            AppSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingViewModel())
}
