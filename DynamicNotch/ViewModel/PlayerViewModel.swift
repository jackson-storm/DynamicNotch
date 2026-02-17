//
//  PlayerNotchViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import Foundation
import SwiftUI
import Combine
import AppKit
import Darwin

final class PlayerViewModel: ObservableObject {
    @Published var title: String = "Не играет"
    @Published var artist: String = "Нет данных"
    @Published var duration: Double = 1
    @Published var currentTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var artwork: Image? = nil
    
    private var timer: Timer?
    private var lastUpdateTimestamp: Date = Date()
    private var playbackRate: Double = 0
    
    init() {
        MediaRemote.load()
        MediaRemote.registerForNotifications?(DispatchQueue.main)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateNowPlaying),
            name: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"), object: nil)
        
        startSmoothTimer()
        updateNowPlaying()
    }
    
    private func startSmoothTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            let delta = Date().timeIntervalSince(self.lastUpdateTimestamp)
            if self.currentTime + delta <= self.duration {
                self.currentTime += delta * self.playbackRate
                self.lastUpdateTimestamp = Date()
            }
        }
    }
    
    @objc func updateNowPlaying() {
        MediaRemote.getNowPlayingInfo?(DispatchQueue.main) { [weak self] cfInfo in
            guard let self = self, let info = (cfInfo as NSDictionary?) as? [String: Any] else {
                DispatchQueue.main.async { self?.resetInfo() }
                return
            }
            
            DispatchQueue.main.async {
                self.title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String ?? "Не играет"
                self.artist = info[kMRMediaRemoteNowPlayingInfoArtist] as? String ?? "Нет данных"
                self.duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double ?? 1
                self.currentTime = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double ?? 0
                self.playbackRate = info[kMRMediaRemoteNowPlayingInfoPlaybackRate] as? Double ?? 0
                self.isPlaying = self.playbackRate > 0
                self.lastUpdateTimestamp = Date()
                
                if let data = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data, let nsImg = NSImage(data: data) {
                    self.artwork = Image(nsImage: nsImg)
                } else {
                    self.artwork = nil
                }
            }
        }
    }
    
    func resetInfo() {
        self.title = "Не играет"; self.artist = "Нет данных"; self.artwork = nil
        self.isPlaying = false; self.currentTime = 0; self.duration = 1
    }
    
    func playPause() { MediaKeySimulator.send(keyCode: 16); updateAfterDelay() }
    func nextTrack() { MediaKeySimulator.send(keyCode: 19); updateAfterDelay() }
    func prevTrack() { MediaKeySimulator.send(keyCode: 20); updateAfterDelay() }
    
    private func updateAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.updateNowPlaying() }
    }
    
    func formatTime(_ time: Double) -> String {
        let t = Int(max(0, time))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

struct MediaKeySimulator {
    static func send(keyCode: Int64) {
        func post(flags: Int) {
            let ev = NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)), timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: Int((keyCode << 16) | ((flags == 0xa00 ? 0xA : 0xB) << 8)), data2: -1)
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        post(flags: 0xa00); post(flags: 0xb00)
    }
}
