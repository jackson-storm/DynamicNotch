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
    @State private var revealBlur: Double = 0
    @State private var revealTask: Task<Void, Never>? = nil

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

    private var displayedImage: NSImage? {
        guard let artworkImage = nowPlayingViewModel.artworkImage else { return nil }
        if artworkImage === lastSourceImage, let cached = cachedResizedImage {
            return cached
        }
        return artworkImage
    }

    var body: some View {
        Group {
            if let artworkImage = displayedImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .overlay(Color.gray.opacity(darknessOverlayOpacity))
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
        .blur(radius: revealBlur)
        .albumArtFlip(angle: nowPlayingViewModel.artworkFlipAngle, isEnabled: usesFlipAnimation)
        .opacity(artworkOpacity)
        .scaleEffect(artworkScale)
        .animation(.easeInOut(duration: 0.25), value: artworkOpacity)
        .animation(.easeInOut(duration: 0.25), value: darknessOverlayOpacity)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: artworkScale)
        .onAppear {
            updateCachedImage()
        }
        .onChange(of: nowPlayingViewModel.artworkImage) {
            let shouldAnimate = usesFlipAnimation && nowPlayingViewModel.isArtworkFlipping
            updateCachedImage()
            if shouldAnimate {
                triggerRevealAnimation()
            }
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

    private var darknessOverlayOpacity: Double {
        let luminance = nowPlayingViewModel.artworkPalette.luminance
        let threshold = 1.0
        guard luminance < threshold else { return 0 }
        let progress = (threshold - luminance) / threshold
        return progress * 0.2
    }

    private func triggerRevealAnimation() {
        revealTask?.cancel()
        revealTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000)
            revealBlur = 10
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                revealBlur = 0
            }
        }
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
