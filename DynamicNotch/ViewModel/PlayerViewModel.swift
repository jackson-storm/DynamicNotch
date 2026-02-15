//
//  PlayerNotchViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import Foundation
import MediaPlayer
import Combine
import SwiftUI

final class PlayerViewModel: ObservableObject {
    @Published var title: String = "Not Playing"
    @Published var artist: String = ""
    @Published var duration: Double = 1
    @Published var currentTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var artwork: Image? = nil
    @Published var artworkColor: Color = .gray
    
    private var timer: Timer?
    
    init() {
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }
    
    private func updateNowPlaying() {
        let infoCenter = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        guard let info = infoCenter else {
            if self.isPlaying {
                self.isPlaying = false
                self.title = "Not Playing"
            }
            return
        }
        
        let newTitle = info[MPMediaItemPropertyTitle] as? String ?? "Unknown"
        let newArtist = info[MPMediaItemPropertyArtist] as? String ?? ""
        
        if self.title != newTitle { self.title = newTitle }
        if self.artist != newArtist { self.artist = newArtist }
        
        self.duration = info[MPMediaItemPropertyPlaybackDuration] as? Double ?? 1
        self.currentTime = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double ?? 0
        
        let rate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0
        self.isPlaying = rate > 0
        
        if let validArtwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            let nsImage = validArtwork.image(at: CGSize(width: 200, height: 200))
            if let nsImage = nsImage {
                self.artwork = Image(nsImage: nsImage)
            }
        } else {
            self.artwork = nil
        }
    }
    
    func playPause() {
        MediaKeySimulator.send(keyCode: 16)
        isPlaying.toggle()
    }
    
    func nextTrack() {
        MediaKeySimulator.send(keyCode: 19)
    }
    
    func prevTrack() {
        MediaKeySimulator.send(keyCode: 20)
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct MediaKeySimulator {
    static func send(keyCode: Int64) {
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xA << 8)),
            data2: -1
        )
        
        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0xB << 8)),
            data2: -1
        )
        
        keyDown?.cgEvent?.post(tap: .cghidEventTap)
        keyUp?.cgEvent?.post(tap: .cghidEventTap)
    }
}
