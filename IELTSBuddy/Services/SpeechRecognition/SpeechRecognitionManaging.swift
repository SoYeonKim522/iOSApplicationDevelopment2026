//
//  SpeechRecognitionManaging.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 14/5/2026.
//

import Foundation
import Combine

@MainActor
protocol SpeechRecognitionManaging: AnyObject {
    var transcript: String { get }
    var isRecording: Bool { get }
    var errorMessage: String? { get }
    var audioFileURL: URL? { get }
    
    var transcriptPublisher: AnyPublisher<String, Never> { get }
    var isRecordingPublisher: AnyPublisher<Bool, Never> { get }
    var errorMessagePublisher: AnyPublisher<String?, Never> { get }
    
    func requestPermissions() async
    func startRecording()
    func stopRecording()
}
