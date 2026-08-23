//
//  NowPlayingMinimalNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
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
        timelineContent(snapshot: snapshot)
    }

    private func timelineContent(snapshot: NowPlayingSnapshot) -> some View {
        HStack {
            ArtworkView(
                nowPlayingViewModel: nowPlayingViewModel,
                width: isDynamicIsland ? 16 : 24,
                height: isDynamicIsland ? 16 : 24,
                cornerRadius: isDynamicIsland ? 3 : 5,
                usesFlipAnimation: settings.isNowPlayingArtwork3DEffectEnabled
            )
            
            Spacer()
            
            LightweightNowPlayingEqualizerView(
                isPlaying: snapshot.isPlaying,
                colors: [
                    nowPlayingViewModel.artworkPalette.equalizerHighlightColor,
                    nowPlayingViewModel.artworkPalette.equalizerBaseColor
                ],
                barHeight: isDynamicIsland ? 12 : 16,
                barWidth: isDynamicIsland ? 1.8 : 2,
            )
            .frame(width: isDynamicIsland ? 14 : 18, height: isDynamicIsland ? 12 : 16)
        }
        .padding(.leading, isDynamicIsland ? 7.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: scale) : 15.scaled(by: scale))
    }
}
