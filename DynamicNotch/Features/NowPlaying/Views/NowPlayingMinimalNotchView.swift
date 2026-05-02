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
            ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 24, height: 24, cornerRadius: 5)
            Spacer()
            LightweightNowPlayingEqualizerView(
                isPlaying: snapshot.isPlaying,
                color: nowPlayingViewModel.artworkPalette.equalizerBaseColor
            )
            .frame(width: 18, height: 16)
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
