//
//  ContentView.swift
//  IELTSBuddy
//
//  Created by yosam on 3/5/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingTestView()
                .tabItem {
                    Label("Practice", systemImage: "mic")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            ReviewLogView()
                .tabItem {
                    Label("Review", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
