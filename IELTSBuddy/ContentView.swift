//
//  ContentView.swift
//  IELTSBuddy
//
//  Created by yosam on 3/5/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    let services: AppServices

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(services: services, goToPractice: { selectedTab = 0 })
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)

            ReviewLogView()
                .tabItem {
                    Label("Review", systemImage: "text.magnifyingglass")
                }
                .tag(2)
            
            AppSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView(services: .preview)
        .environmentObject(OnboardingViewModel())
}
