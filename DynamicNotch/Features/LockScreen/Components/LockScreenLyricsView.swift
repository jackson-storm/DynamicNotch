//
//  LockScreenLyricsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import SwiftUI
internal import AppKit

struct LockScreenLyricsView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    let width: CGFloat
    private let height: CGFloat = 520
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.35)) { context in
            LockScreenLyricsContentView(
                state: nowPlayingViewModel.lyricsState,
                activeIndex: activeIndex(at: context.date),
                width: width,
                height: height,
                onSeek: { startTime in
                    nowPlayingViewModel.seek(to: startTime)
                }
            )
            .equatable()
        }
    }
    
    private func activeIndex(at date: Date) -> Int {
        let elapsedTime = nowPlayingViewModel.lyricsPlaybackTime(at: date)
        if case .loaded(let lyrics) = nowPlayingViewModel.lyricsState {
            return lyrics.activeLineIndex(at: elapsedTime) ?? 0
        }
        return 0
    }
}

private struct LockScreenLyricsContentView: View, Equatable {
    let state: NowPlayingLyricsState
    let activeIndex: Int
    let width: CGFloat
    let height: CGFloat
    let onSeek: (TimeInterval) -> Void
    
    static func == (lhs: LockScreenLyricsContentView, rhs: LockScreenLyricsContentView) -> Bool {
        lhs.state == rhs.state &&
        lhs.activeIndex == rhs.activeIndex &&
        lhs.width == rhs.width &&
        lhs.height == rhs.height
    }
    
    var body: some View {
        content()
            .frame(width: width, height: height, alignment: .leading)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.12),
                        .init(color: .black, location: 0.88),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch state {
        case .idle:
            EmptyView()
            
        case .loading:
            LockScreenLyricsLoadingView(width: width, height: height)
            
        case .loaded(let lyrics):
            if lyrics.lines.isEmpty {
                unavailableContent(title: "The lyrics were not found")
            } else if lyrics.isSynced {
                LockScreenSyncedLyricsView(
                    lyrics: lyrics,
                    activeIndex: activeIndex,
                    width: width,
                    height: height,
                    onSeek: onSeek
                )
            } else {
                plainLyricsContent(lyrics)
            }
            
        case .notFound:
            unavailableContent(title: "The lyrics were not found")
            
        case .failed:
            unavailableContent(title: "The lyrics didn't load")
        }
    }
    
    private func plainLyricsContent(_ lyrics: TrackLyrics) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(lyrics.lines) { line in
                    Text(line.text)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(lyrics.trackKey)
        .frame(width: width, height: height)
        .transition(.opacity)
    }
    
    private func unavailableContent(title: String, systemImage: String = "quote.bubble") -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(.white.opacity(0.32))
            
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
        }
        .frame(width: width, height: height, alignment: .center)
        .transition(.opacity)
    }
}

private struct LockScreenSyncedLyricsView: View {
    let lyrics: TrackLyrics
    let activeIndex: Int
    let width: CGFloat
    let height: CGFloat
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(lyrics.lines) { line in
                        LockScreenLyricLineView(
                            line: line,
                            distanceFromActive: line.id - activeIndex,
                            onTap: line.startTime.map { startTime in
                                {
                                    onSeek(startTime)
                                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                                        proxy.scrollTo(line.id, anchor: .center)
                                    }
                                }
                            }
                        )
                        .id(line.id)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, height * 0.42)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .id(lyrics.trackKey)
            .frame(width: width, height: height)
            .onChange(of: activeIndex) { _, newIndex in
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(activeIndex, anchor: .center)
                }
            }
        }
    }
}

private struct LockScreenLyricLineView: View {
    let line: LyricLine
    let distanceFromActive: Int
    let onTap: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    private var isActive: Bool {
        distanceFromActive == 0
    }
    
    private var distance: Int {
        abs(distanceFromActive)
    }
    
    private var displayText: String {
        let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "•••" : line.text
    }
    
    private var blurRadius: CGFloat {
        if isActive {
            return 0
        }
        if isHovered {
            return 0.4
        }
        switch distance {
        case 1:
            return 1.4
        case 2:
            return 2.2
        default:
            return min(3.8, 2.2 + CGFloat(distance - 2) * 0.45)
        }
    }
    
    private var lineOpacity: Double {
        if isActive {
            return 1.0
        }
        if isHovered {
            return 0.85
        }
        switch distance {
        case 1:
            return 0.52
        case 2:
            return 0.36
        default:
            return max(0.18, 0.36 - Double(distance - 2) * 0.05)
        }
    }
    
    private var lineScale: CGFloat {
        if isActive {
            return 1.0
        }
        if isHovered {
            return 0.985
        }
        switch distance {
        case 1:
            return 0.965
        case 2:
            return 0.945
        default:
            return max(0.90, 0.945 - CGFloat(distance - 2) * 0.012)
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .lineSpacing(6)
            .foregroundStyle(.white)
            .opacity(lineOpacity)
            .blur(radius: blurRadius)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isHovered && !isActive ? 0.08 : 0))
            )
            .scaleEffect(lineScale * (isPressed ? 0.96 : 1.0), anchor: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard let onTap = onTap else { return }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
                onTap()
            }
            .onHover { hovering in
                guard onTap != nil else { return }
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDisappear {
                if isHovered {
                    NSCursor.pop()
                    isHovered = false
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: isActive)
            .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

private struct LockScreenLyricsLoadingView: View {
    let width: CGFloat
    let height: CGFloat
    
    @State private var shimmerPhase: CGFloat = -0.6
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(0..<5, id: \.self) { index in
                let isActive = index == 2
                
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(isActive ? 0.35 : 0.15))
                    .frame(
                        width: width * CGFloat([0.6, 0.85, 0.95, 0.72, 0.5][index]),
                        height: isActive ? 34 : 26
                    )
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .mask(
            LinearGradient(
                colors: [.black.opacity(0.25), .black, .black.opacity(0.25)],
                startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0.5),
                endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0.5)
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.6
            }
        }
    }
}
