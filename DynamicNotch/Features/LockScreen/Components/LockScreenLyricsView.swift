//
//  LockScreenLyricsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import SwiftUI

struct LockScreenLyricsView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    let width: CGFloat
    
    private let height: CGFloat = 520
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.35)) { context in
            content(elapsedTime: nowPlayingViewModel.elapsedTime(at: context.date))
        }
        .frame(width: width, height: height, alignment: .leading)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.18),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .shadow(color: .black.opacity(0.34), radius: 16, x: 0, y: 10)
    }
    
    @ViewBuilder
    private func content(elapsedTime: TimeInterval) -> some View {
        switch nowPlayingViewModel.lyricsState {
        case .idle:
            EmptyView()
        case .loading:
            loadingContent
        case .loaded(let lyrics):
            if lyrics.isSynced {
                syncedLyricsContent(lyrics, elapsedTime: elapsedTime)
            } else {
                plainLyricsContent(lyrics)
            }
        case .notFound:
            unavailableContent(title: "Lyrics not found")
        case .failed:
            unavailableContent(title: "Lyrics failed to load")
        }
    }
    
    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<6, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(.white.opacity(index == 1 ? 0.26 : 0.14))
                    .frame(
                        width: width * CGFloat([0.72, 0.92, 0.62, 0.84, 0.58, 0.76][index]),
                        height: index == 1 ? 26 : 18
                    )
            }
        }
        .frame(width: width, height: height, alignment: .center)
    }
    
    private func syncedLyricsContent(_ lyrics: TrackLyrics, elapsedTime: TimeInterval) -> some View {
        let activeIndex = lyrics.activeLineIndex(at: elapsedTime) ?? 0
        let visibleLines = visibleSyncedLines(lyrics.lines, activeIndex: activeIndex)
        
        return VStack(alignment: .leading, spacing: 24) {
            ForEach(visibleLines) { line in
                LockScreenLyricLineView(
                    line: line,
                    distanceFromActive: line.id - activeIndex
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: activeIndex)
    }
    
    private func plainLyricsContent(_ lyrics: TrackLyrics) -> some View {
        let visibleLines = Array(lyrics.lines.prefix(9))
        let centerIndex = visibleLines.count / 2
        
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(visibleLines.enumerated()), id: \.element.id) { index, line in
                LockScreenLyricLineView(
                    line: line,
                    distanceFromActive: index - centerIndex
                )
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .transition(.opacity)
    }
    
    private func unavailableContent(title: String) -> some View {
        Text(title)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.38))
            .frame(width: width, height: height, alignment: .center)
            .transition(.opacity)
    }
    
    private func visibleSyncedLines(_ lines: [LyricLine], activeIndex: Int) -> [LyricLine] {
        guard lines.isEmpty == false else { return [] }
        
        let lowerBound = max(0, activeIndex - 4)
        let upperBound = min(lines.count - 1, activeIndex + 4)
        return Array(lines[lowerBound...upperBound])
    }
}

private struct LockScreenLyricLineView: View {
    let line: LyricLine
    let distanceFromActive: Int
    
    private var isActive: Bool {
        distanceFromActive == 0
    }
    
    private var clampedDistance: CGFloat {
        min(CGFloat(abs(distanceFromActive)), 4)
    }
    
    private var lineOpacity: Double {
        if isActive {
            return 0.98
        }
        
        return max(0.12, 0.42 - (Double(clampedDistance) * 0.12))
    }
    
    private var lineScale: CGFloat {
        max(0.72, 1 - (clampedDistance * 0.085))
    }
    
    private var blurRadius: CGFloat {
        isActive ? 0 : clampedDistance * 0.18
    }
    
    private var rotationAngle: Angle {
        .degrees(Double(distanceFromActive) * -7)
    }

    private var rotationAnchor: UnitPoint {
        distanceFromActive < 0 ? .center : .center
    }
    
    var body: some View {
        Text(line.text)
            .font(.system(size: isActive ? 34 : 30, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(lineOpacity))
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.leading)
            .blur(radius: blurRadius)
            .scaleEffect(lineScale, anchor: .leading)
            .rotation3DEffect(
                rotationAngle,
                axis: (x: 0, y: 0, z: 0),
                anchor: rotationAnchor,
                perspective: 0.72
            )
            .offset(x: isActive ? 0 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentTransition(.opacity)
            .zIndex(Double(10 - clampedDistance))
    }
}
