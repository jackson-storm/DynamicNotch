//
//  LockScreenNowPlayingPanel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/15/26.
//

import SwiftUI
internal import AppKit
import Combine

struct LockScreenNowPlayingPanelView: View {
    static let panelSize = CGSize(width: 340, height: 180)
    
    private static let expandedPanelHeight: CGFloat = panelSize.height - 20
    private static let expandedArtworkSize: CGFloat = 500
    private static let expandedArtworkSpacing: CGFloat = 90
    private static let expandedStackLift: CGFloat = 160
    private static let expandedClockHeight: CGFloat = 76
    private static let expandedClockArtworkSpacing: CGFloat = 20
    private static let expandedLyricsWidth: CGFloat = 520
    private static let expandedLyricsSpacing: CGFloat = 90
    private static let panelCenterYOffset: CGFloat = (Self.panelSize.height / 2) + 80
    private static let backgroundScaleRange: ClosedRange<CGFloat> = 1...2
    private static let rotationOverscanScale: CGFloat = 1.04
    
    let snapshot: NowPlayingSnapshot
    let artworkImage: NSImage?
    let screen: NSScreen
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenPanelAnimator
    
    @State private var scrubProgress: CGFloat?
    @State private var onTapArtwork: Bool = false
    @State private var backgroundRotation: Double = 0
    @State private var backgroundScale: CGFloat = 1
    @State private var wallpaperImage: NSImage?
    
    private let animationTick: TimeInterval = 1.0 / 10.0
    
    var body: some View {
        GeometryReader { screenProxy in
            let screenWidth = screenProxy.size.width
            let screenHeight = screenProxy.size.height
            
            ZStack {
                if onTapArtwork {
                    artworkPresentationBackground
                        .onAppear(perform: configureMediaPanelBackgroundAnimation)
                        .onChange(of: mediaPanelBackgroundStyle) {
                            configureMediaPanelBackgroundAnimation()
                        }
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                if onTapArtwork {
                    expandedClockView
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .offset(y: -screenHeight / 2 + 130)
                }
                
                if onTapArtwork {
                    expandedArtworkButton
                        .transition(.scale(scale: 0.82).combined(with: .opacity))
                        .offset(x: expandedArtworkXOffset, y: -42)
                }
                
                if shouldShowExpandedLyrics {
                    LockScreenLyricsView(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: Self.expandedLyricsWidth
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .offset(x: expandedLyricsXOffset, y: -42)
                }
                
                playerPanel
                    .offset(x: 0, y: playerPanelYOffset(screenHeight: screenHeight))
            }
            .frame(width: screenWidth, height: screenHeight)
        }
        .opacity(animator.isPresented ? 1 : 0)
        .animation(.spring(response: 0.3), value: animator.isPresented)
        .animation(.spring(response: 0.58, dampingFraction: 0.86), value: onTapArtwork)
        .animation(.spring(response: 0.58, dampingFraction: 0.86), value: shouldShowExpandedLyrics)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear(perform: syncLyricsPresentationState)
        .onDisappear {
            nowPlayingViewModel.setLyricsPresentationActive(false)
        }
        .onChange(of: onTapArtwork) {
            syncLyricsPresentationState()
        }
        .onChange(of: settingsViewModel.lockScreen.isLockScreenLyricsEnabled) {
            syncLyricsPresentationState()
        }
        .onChange(of: nowPlayingViewModel.snapshot?.lyricsLookupKey) {
            syncLyricsPresentationState()
        }
        .onAppear {
            if mediaPanelBackgroundStyle == .wallpaper {
                loadWallpaperImage()
            }
        }
        .onChange(of: mediaPanelBackgroundStyle) {
            if mediaPanelBackgroundStyle == .wallpaper {
                loadWallpaperImage()
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
            if mediaPanelBackgroundStyle == .wallpaper {
                loadWallpaperImage()
            }
        }
    }

    private var playerPanel: some View {
        LockScreenNowPlayingView(
            nowPlayingViewModel: nowPlayingViewModel,
            mediaSettings: settingsViewModel.mediaAndFiles,
            onTapArtwork: $onTapArtwork
        )
        .frame(
            width: Self.panelSize.width,
            height: onTapArtwork ? Self.expandedPanelHeight : Self.panelSize.height,
            alignment: .topLeading
        )
        .background {
            panelBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .environment(\.colorScheme, .dark)
        .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
    }

    private var expandedArtworkButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.65)) {
                onTapArtwork = false
            }
        }) {
            ArtworkView(
                nowPlayingViewModel: nowPlayingViewModel,
                width: Self.expandedArtworkSize,
                height: Self.expandedArtworkSize,
                cornerRadius: 30,
                usesFlipAnimation: true
            )
            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 16)
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }

    private var expandedClockView: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            LockScreenClockView(
                date: context.date,
                width: Self.expandedArtworkSize + 120,
                height: Self.expandedClockHeight
            )
        }
    }

    private var shouldShowExpandedLyrics: Bool {
        onTapArtwork && settingsViewModel.lockScreen.isLockScreenLyricsEnabled
    }

    private var expandedArtworkXOffset: CGFloat {
        guard shouldShowExpandedLyrics else { return 0 }
        return -((Self.expandedLyricsWidth + Self.expandedLyricsSpacing) / 2)
    }

    private var expandedLyricsXOffset: CGFloat {
        (Self.expandedArtworkSize + Self.expandedLyricsSpacing) / 2
    }

    private func playerPanelYOffset(screenHeight: CGFloat) -> CGFloat {
        if onTapArtwork {
            return screenHeight / 2 - 180
        } else {
            return Self.panelCenterYOffset + activeMediaPanelVerticalOffset
        }
    }

    private var mediaPanelVerticalOffset: CGFloat {
        CGFloat(settingsViewModel.lockScreen.mediaPanelVerticalOffset)
    }

    private var activeMediaPanelVerticalOffset: CGFloat {
        onTapArtwork ? 0 : mediaPanelVerticalOffset
    }

    private var mediaPanelBackgroundStyle: LockScreenMediaPanelBackgroundStyle {
        settingsViewModel.lockScreen.mediaPanelBackgroundStyle
    }

    private var mediaPanelBackgroundScale: CGFloat {
        mediaPanelBackgroundStyle == .animatedArtwork ?
        backgroundScale :
        1
    }

    private var mediaPanelBackgroundRotation: Angle {
        mediaPanelBackgroundStyle == .animatedArtwork ?
        .degrees(backgroundRotation) :
        .zero
    }

    private func configureMediaPanelBackgroundAnimation() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            backgroundRotation = 0
            backgroundScale = Self.backgroundScaleRange.lowerBound
        }

        guard
            mediaPanelBackgroundStyle == .animatedArtwork
        else {
            return
        }

        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            backgroundRotation = 360
        }

        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            backgroundScale = Self.backgroundScaleRange.upperBound
        }
    }

    @ViewBuilder
    private var artworkPresentationBackground: some View {
        coverAndBackgroundPresentation
    }

    private var coverAndBackgroundPresentation: some View {
        GeometryReader { proxy in
            let diagonal = hypot(proxy.size.width, proxy.size.height) * Self.rotationOverscanScale
            ZStack {
                Color.black

                if mediaPanelBackgroundStyle != .black {
                    if mediaPanelBackgroundStyle == .wallpaper {
                        NowPlayingArtworkBackground(
                            artworkImage: resolvedArtworkImage,
                            blurRadius: 10,
                            darkeningOpacity: 0.6,
                            saturation: 1.00,
                            scale: 1.0
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    } else {
                        NowPlayingArtworkBackground(
                            artworkImage: resolvedArtworkImage,
                            blurRadius: 200,
                            darkeningOpacity: 0.6,
                            saturation: 1.45,
                            scale: mediaPanelBackgroundScale
                        )
                        .frame(width: diagonal, height: diagonal)
                        .rotationEffect(mediaPanelBackgroundRotation)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    @ViewBuilder
    private var panelBackground: some View {
        LockScreenWidgetSurface(
            style: settingsViewModel.lockScreen.widgetAppearanceStyle,
            tintStyle: settingsViewModel.lockScreen.widgetTintStyle,
            brightness: settingsViewModel.lockScreen.widgetBackgroundBrightness,
            cornerRadius: 28,
            liquidGlassVariant: settingsViewModel.lockScreen.liquidGlassVariant
        )
    }

    private var resolvedArtworkImage: NSImage? {
        if mediaPanelBackgroundStyle == .wallpaper {
            return wallpaperImage ?? artworkImage ?? nowPlayingViewModel.artworkImage
        }
        return artworkImage ?? nowPlayingViewModel.artworkImage
    }

    private func loadWallpaperImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else {
                return
            }
            let image = NSImage(contentsOf: url)
            DispatchQueue.main.async {
                self.wallpaperImage = image
            }
        }
    }

    private func syncLyricsPresentationState() {
        nowPlayingViewModel.setLyricsPresentationActive(shouldShowExpandedLyrics)
    }
}
