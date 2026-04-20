//
//  NowPlayingMinimalNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore

    private let audioReactiveVisibilitySource = "nowPlaying.notch.minimal"
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Nothing artists",
            album: "",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot

        return TimelineView(.periodic(from: .now, by: animationTick(for: snapshot))) { context in
            timelineContent(snapshot: snapshot, at: context.date)
        }
        .onAppear {
            nowPlayingViewModel.setAudioReactiveVisualizationActive(
                true,
                source: audioReactiveVisibilitySource
            )
        }
        .onDisappear {
            nowPlayingViewModel.setAudioReactiveVisualizationActive(
                false,
                source: audioReactiveVisibilitySource
            )
        }
    }

    private func timelineContent(snapshot: NowPlayingSnapshot, at date: Date) -> some View {
        HStack {
            ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 24, height: 24, cornerRadius: 5)
            Spacer()
            EqualizerView(
                isPlaying: snapshot.isPlaying,
                mode: settings.nowPlayingEqualizerMode,
                palette: nowPlayingViewModel.artworkPalette,
                trackSeed: snapshot.waveSeed,
                audioLevels: nowPlayingViewModel.audioReactiveLevels,
                date: date,
                width: 2,
                height: 2
            )
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }

    private func animationTick(for snapshot: NowPlayingSnapshot) -> TimeInterval {
        snapshot.isPlaying ? (1.0 / 14.0) : 0.5
    }
}
