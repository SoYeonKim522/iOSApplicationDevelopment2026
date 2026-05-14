//
//  AVAudioPlaybackManager.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 14/5/2026.
//

import AVFoundation
import Foundation

final class AVAudioPlaybackManager: NSObject, AudioPlaybackManaging, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    var isPlaying: Bool { player?.isPlaying == true }
    var onFinished: (() -> Void)?

    func play(url: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        let p = try AVAudioPlayer(contentsOf: url)
        p.delegate = self
        p.prepareToPlay()
        p.play()
        player = p
    }

    func stop() {
        player?.stop()
        player = nil
    }
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinished?()
    }
}
