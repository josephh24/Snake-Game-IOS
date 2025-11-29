//
//  AudioManager.swift
//  test
//
//  Created by jose pablo sanchez guillen on 21/11/25.
//

import Foundation
import AVFoundation
import AudioToolbox

final class AudioManager {
    static let shared = AudioManager()
    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        preload("eat")
        preload("gameover")
        preload("click")
    }

    private func preload(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            players[name] = p
        } catch {
            // no crash: fallback later
        }
    }

    func playEat() { play(name: "eat", fallbackSystemID: 1157) }        // short beep
    func playGameOver() { play(name: "gameover", fallbackSystemID: 1155) } // low tone
    func playClick() { play(name: "click", fallbackSystemID: 1104) }    // tap

    private func play(name: String, fallbackSystemID: SystemSoundID) {
        if let p = players[name] {
            p.currentTime = 0
            p.play()
        } else {
            AudioServicesPlaySystemSound(fallbackSystemID)
        }
    }
}
