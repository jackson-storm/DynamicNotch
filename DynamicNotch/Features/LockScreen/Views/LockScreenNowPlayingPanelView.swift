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
    let snapshot: NowPlayingSnapshot
    let artworkImage: NSImage?
    let screen: NSScreen
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenPanelAnimator
    
    @State private var scrubProgress: CGFloat?
    @State private var onTapArtwork: Bool
    @State private var showLyrics: Bool
    @State private var backgroundRotation: Double = 0
    @State private var backgroundScale: CGFloat = 1
    
    private let animationTick: TimeInterval = 1.0 / 10.0
    
    init(
        snapshot: NowPlayingSnapshot,
        artworkImage: NSImage?,
        screen: NSScreen,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager,
        animator: LockScreenPanelAnimator
    ) {
        self.snapshot = snapshot
        self.artworkImage = artworkImage
        self.screen = screen
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        self.animator = animator
        self._onTapArtwork = State(initialValue: settingsViewModel.lockScreen.isLockScreenArtworkExpanded)
        self._showLyrics = State(initialValue: settingsViewModel.lockScreen.isLockScreenLyricsShown)
    }
    
    var body: some View {
        GeometryReader { screenProxy in
            let screenWidth = screenProxy.size.width
            let screenHeight = screenProxy.size.height
            
            ZStack {
                if onTapArtwork {
                    coverAndBackgroundPresentation
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    clockView
                        .transition(
                            .blurAndFade
                                .animation(.easeInOut(duration: 0.6))
                                .combined(with: .scale(scale: 0.6, anchor: .top))
                                .combined(with: .opacity)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 80)
                    
                    HStack(spacing: 100) {
                        artworkButton
                        
                        if showLyrics && onTapArtwork == true {
                            LockScreenLyricsView(nowPlayingViewModel: nowPlayingViewModel)
                                .transition(
                                    .blurAndFade
                                        .animation(.easeInOut(duration: 0.6))
                                        .combined(with: .move(edge: .trailing))
                                        .combined(with: .opacity)
                                )
                        }
                    }
                    .transition(
                        .blurAndFade
                            .animation(.easeInOut(duration: 0.6))
                            .combined(with: .scale(scale: 0.8))
                            .combined(with: .opacity)
                    )
                    .padding(.bottom, 60)
                }
                playerPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, playerPanelYOffset)
                
                buttonsControl
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: screenWidth, height: screenHeight)
        }
        .opacity(animator.isPresented ? 1 : 0)
        .environment(\.controlActiveState, .active)
        .environment(\.colorScheme, .dark)
        .animation(.spring(response: 0.5), value: animator.isPresented)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: onTapArtwork)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLyrics)
        .onAppear {
            if onTapArtwork != settingsViewModel.lockScreen.isLockScreenArtworkExpanded {
                onTapArtwork = settingsViewModel.lockScreen.isLockScreenArtworkExpanded
            }
            if showLyrics != settingsViewModel.lockScreen.isLockScreenLyricsShown {
                showLyrics = settingsViewModel.lockScreen.isLockScreenLyricsShown
            }
            syncLyricsPresentationState()
        }
        .onDisappear {
            settingsViewModel.lockScreen.isLockScreenLyricsShown = showLyrics
            nowPlayingViewModel.setLyricsPresentationActive(false)
        }
        .onChange(of: showLyrics) { _, newValue in
            if settingsViewModel.lockScreen.isLockScreenLyricsShown != newValue {
                settingsViewModel.lockScreen.isLockScreenLyricsShown = newValue
            }
            syncLyricsPresentationState()
        }
        .onChange(of: onTapArtwork) { _, newValue in
            if settingsViewModel.lockScreen.isLockScreenArtworkExpanded != newValue {
                settingsViewModel.lockScreen.isLockScreenArtworkExpanded = newValue
            }
            syncLyricsPresentationState()
        }
        .onChange(of: nowPlayingViewModel.snapshot?.lyricsLookupKey) {
            syncLyricsPresentationState()
        }
    }
    
    private var buttonsControl: some View {
        VStack(spacing: 20) {
            Button(action: {
                onTapArtwork.toggle()
            }) {
                Image(systemName: onTapArtwork ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
            }
            .modifier(QuoteButtonAdaptiveStyle())
            
            if onTapArtwork {
                Button(action: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showLyrics.toggle()
                    }
                }) {
                    Image(systemName: showLyrics ? "text.page.slash.fill" : "quote.bubble.fill")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                }
                .modifier(QuoteButtonAdaptiveStyle())
            }
        }
        .padding()
    }
    
    private var playerPanel: some View {
        LockScreenNowPlayingView(
            nowPlayingViewModel: nowPlayingViewModel,
            mediaSettings: settingsViewModel.mediaAndFiles,
            onTapArtwork: $onTapArtwork
        )
        .frame(width: 340, height: onTapArtwork ? 160 : 180)
        .modifier(PlayerPanelGlassModifier(cornerRadius: 28))
    }
    
    private var artworkButton: some View {
        Button(action: {
            onTapArtwork = false
        }) {
            ArtworkView(
                nowPlayingViewModel: nowPlayingViewModel,
                width: 500,
                height: 500,
                cornerRadius: 30,
                usesFlipAnimation: true
            )
            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 16)
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }
    
    private var clockView: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            LockScreenClockView(date: context.date, width: 620, height: 76)
        }
    }
    
    private var playerPanelYOffset: CGFloat {
        if onTapArtwork {
            return 80 + activeMediaPanelVerticalOffset
        } else {
            return 230 + activeMediaPanelVerticalOffset
        }
    }
    
    private var activeMediaPanelVerticalOffset: CGFloat {
        onTapArtwork ? 0 : CGFloat(settingsViewModel.lockScreen.mediaPanelVerticalOffset)
    }
    
    private var mediaPanelBackgroundStyle: LockScreenMediaPanelBackgroundStyle {
        settingsViewModel.lockScreen.mediaPanelBackgroundStyle
    }
    
    private var coverAndBackgroundPresentation: some View {
        GeometryReader { proxy in
            let diagonal = hypot(proxy.size.width, proxy.size.height)
            ZStack {
                Color.black
                
                if mediaPanelBackgroundStyle != .black {
                    NowPlayingArtworkBackground(
                        artworkImage: resolvedArtworkImage,
                        blurRadius: 50,
                        darkeningOpacity: 0.6,
                        saturation: 1.45,
                        scale: mediaPanelBackgroundScale
                    )
                    .frame(width: diagonal, height: diagonal)
                    .rotationEffect(mediaPanelBackgroundRotation)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear(perform: configureMediaPanelBackgroundAnimation)
            .onChange(of: mediaPanelBackgroundStyle) {
                configureMediaPanelBackgroundAnimation()
            }
        }
    }
    
    private var mediaPanelBackgroundScale: CGFloat {
        mediaPanelBackgroundStyle == .animatedArtwork ? backgroundScale : 1
    }
    
    private var mediaPanelBackgroundRotation: Angle {
        mediaPanelBackgroundStyle == .animatedArtwork ? .degrees(backgroundRotation) : .zero
    }
    
    private func configureMediaPanelBackgroundAnimation() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            backgroundRotation = 0
            backgroundScale = 1
        }
        
        guard mediaPanelBackgroundStyle == .animatedArtwork else {
            return
        }
        
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            backgroundRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            backgroundScale = 2
        }
    }
    
    private var resolvedArtworkImage: NSImage? {
        artworkImage ?? nowPlayingViewModel.artworkImage
    }
    
    private func syncLyricsPresentationState() {
        nowPlayingViewModel.setLyricsPresentationActive(showLyrics)
    }
}

private struct QuoteButtonAdaptiveStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .buttonStyle(.plain)
        }
    }
}

private struct PlayerPanelGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
        }
    }
}
