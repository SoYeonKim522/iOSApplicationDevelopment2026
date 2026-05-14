//
//  AudioPlaybackManaging.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 14/5/2026.
//

import Foundation

protocol AudioPlaybackManaging: AnyObject {
    var isPlaying: Bool { get }
    var onFinished: (() -> Void)? { get set }
    func play(url: URL) throws
    func stop()
}
