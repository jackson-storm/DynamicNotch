//
//  ArtworkView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct ArtworkView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    private var artworkScale: CGFloat {
        guard nowPlayingViewModel.snapshot != nil else { return 1 }
        return nowPlayingViewModel.snapshot?.isPlaying == true ? 1 : 0.84
    }
    
    private var artworkOpacity: Double {
        guard nowPlayingViewModel.snapshot != nil else { return 1 }
        return nowPlayingViewModel.snapshot?.isPlaying == true ? 1 : 0.3
    }

    var body: some View {
        Group {
            if let artworkImage = nowPlayingViewModel.artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .albumArtFlip(angle: nowPlayingViewModel.artworkFlipAngle)
        .opacity(artworkOpacity)
        .scaleEffect(artworkScale)
        .animation(.easeInOut(duration: 0.18), value: artworkOpacity)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: artworkScale)
    }
}

private struct AlbumArtFlipModifier: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.5
            )
            .scaleEffect(x: cosineSign(for: angle), y: 1)
    }

    private func cosineSign(for degrees: Double) -> CGFloat {
        let cosine = cos(degrees * .pi / 180)

        if cosine > 0.001 { return 1 }
        if cosine < -0.001 { return -1 }

        return degrees.truncatingRemainder(dividingBy: 360) >= 0 ? -1 : 1
    }
}

private extension View {
    func albumArtFlip(angle: Double) -> some View {
        modifier(AlbumArtFlipModifier(angle: angle))
    }
}
