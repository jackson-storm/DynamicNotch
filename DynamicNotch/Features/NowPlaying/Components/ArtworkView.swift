//
//  ArtworkView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI
internal import AppKit

struct ArtworkView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel

    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let usesFlipAnimation: Bool

    @State private var cachedResizedImage: NSImage?
    @State private var lastSourceImage: NSImage?

    init(
        nowPlayingViewModel: NowPlayingViewModel,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        usesFlipAnimation: Bool = true
    ) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.usesFlipAnimation = usesFlipAnimation
    }

    var body: some View {
        Group {
            if let artworkImage = nowPlayingViewModel.artworkImage {
                Image(nsImage: cachedResizedImage ?? artworkImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
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
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), style: FillStyle(antialiased: true))
        .albumArtFlip(angle: nowPlayingViewModel.artworkFlipAngle, isEnabled: usesFlipAnimation)
        .opacity(artworkOpacity)
        .scaleEffect(artworkScale)
        .animation(.easeInOut(duration: 0.18), value: artworkOpacity)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: artworkScale)
        .onAppear {
            updateCachedImage()
        }
        .onChange(of: nowPlayingViewModel.artworkImage) {
            updateCachedImage()
        }
    }
    
    private var artworkScale: CGFloat {
        guard nowPlayingViewModel.snapshot != nil else { return 1 }
        return nowPlayingViewModel.snapshot?.isPlaying == true ? 1 : 0.84
    }
    
    private var artworkOpacity: Double {
        guard nowPlayingViewModel.snapshot != nil else { return 1 }
        return nowPlayingViewModel.snapshot?.isPlaying == true ? 1 : 0.3
    }

    private func updateCachedImage() {
        guard let artworkImage = nowPlayingViewModel.artworkImage else {
            cachedResizedImage = nil
            lastSourceImage = nil
            return
        }
        guard artworkImage !== lastSourceImage else { return }
        lastSourceImage = artworkImage
        
        let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2.0
        let targetSize = NSSize(width: width * scale, height: height * scale)
        
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .high
            context.shouldAntialias = true
        }
        artworkImage.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: artworkImage.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        resized.unlockFocus()
        cachedResizedImage = resized
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
    @ViewBuilder
    func albumArtFlip(angle: Double, isEnabled: Bool) -> some View {
        if isEnabled {
            modifier(AlbumArtFlipModifier(angle: angle))
        } else {
            self
        }
    }
}
