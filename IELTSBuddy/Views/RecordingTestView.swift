//
//  RecordingTestView.swift
//  IELTSBuddy
//

import SwiftUI

struct RecordingTestView: View {
    @StateObject private var manager = SpeechRecognitionManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let error = manager.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            ScrollView {
                Text(manager.transcript.isEmpty ? "Start speaking..." : manager.transcript)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .foregroundStyle(manager.transcript.isEmpty ? .secondary : .primary)
            }
            .frame(maxHeight: .infinity)

            Button(manager.isRecording ? "Stop Recording" : "Start Recording") {
                if manager.isRecording {
                    manager.stopRecording()
                } else {
                    manager.startRecording()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .onAppear {
            Task {
                await manager.requestPermissions()
            }
        }
    }
}

#Preview {
    RecordingTestView()
}
