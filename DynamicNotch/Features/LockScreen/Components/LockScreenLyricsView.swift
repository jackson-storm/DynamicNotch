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
            let lyricsContent = content(elapsedTime: nowPlayingViewModel.elapsedTime(at: context.date))
                .frame(width: width, height: height, alignment: .leading)
                .clipped()
            
            ZStack {
                lyricsContent
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.10),
                                .init(color: .black, location: 0.22),
                                .init(color: .black, location: 0.78),
                                .init(color: .clear, location: 0.90),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                lyricsContent
                    .blur(radius: 3)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.10),
                                .init(color: .clear, location: 0.26),
                                .init(color: .clear, location: 0.74),
                                .init(color: .black, location: 0.90),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
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
    }
    
    @ViewBuilder
    private func content(elapsedTime: TimeInterval) -> some View {
        switch nowPlayingViewModel.lyricsState {
        case .idle:
            EmptyView()
            
        case .loading:
            LockScreenLyricsLoadingView(width: width, height: height)
            
        case .loaded(let lyrics):
            if lyrics.isSynced {
                syncedLyricsContent(lyrics, elapsedTime: elapsedTime)
            } else {
                plainLyricsContent(lyrics)
            }
            
        case .notFound:
            unavailableContent(title: "The lyrics were not found")
            
        case .failed:
            unavailableContent(title: "The lyrics didn't load")
        }
    }
    
    private func syncedLyricsContent(_ lyrics: TrackLyrics, elapsedTime: TimeInterval) -> some View {
        let activeIndex = lyrics.activeLineIndex(at: elapsedTime) ?? 0
        let visibleLines = visibleSyncedLines(lyrics.lines, activeIndex: activeIndex)
        
        return VStack(alignment: .leading, spacing: 20) {
            ForEach(visibleLines) { line in
                LockScreenLyricLineView(
                    line: line,
                    distanceFromActive: line.id - activeIndex,
                    onTap: line.startTime.map { startTime in
                        {
                            nowPlayingViewModel.seek(to: startTime)
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
            }
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: activeIndex)
    }
    
    private func plainLyricsContent(_ lyrics: TrackLyrics) -> some View {
        let visibleLines = Array(lyrics.lines.prefix(9))
        let centerIndex = visibleLines.count / 2
        
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(visibleLines.enumerated()), id: \.element.id) { index, line in
                LockScreenLyricLineView(
                    line: line,
                    distanceFromActive: index - centerIndex,
                    onTap: nil
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
        
        var result: [LyricLine] = []
        for i in (activeIndex - 4)...(activeIndex + 4) {
            if i >= 0 && i < lines.count {
                result.append(lines[i])
            } else {
                result.append(LyricLine(id: i, startTime: nil, text: " "))
            }
        }
        return result
    }
}

private struct LockScreenLyricLineView: View {
    let line: LyricLine
    let distanceFromActive: Int
    let onTap: (() -> Void)?
    
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
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(lineOpacity))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
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
            .onTapGesture {
                onTap?()
            }
            .onHover { inside in
                guard onTap != nil else { return }
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

private struct LockScreenLyricsLoadingView: View {
    let width: CGFloat
    let height: CGFloat
    
    @State private var shimmerPhase: CGFloat = -0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(0..<5, id: \.self) { index in
                let isActive = index == 2
                
                RoundedRectangle(cornerRadius: isActive ? 12 : 8, style: .continuous)
                    .fill(.white.opacity(isActive ? 0.35 : 0.15))
                    .frame(
                        width: width * CGFloat([0.65, 0.85, 0.95, 0.75, 0.55][index]),
                        height: isActive ? 36 : 24
                    )
            }
        }
        .frame(width: width, height: height, alignment: .center)
        .mask(
            LinearGradient(
                colors: [.black.opacity(0.3), .black, .black.opacity(0.3)],
                startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0.5),
                endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 0.5)
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.5
            }
        }
    }
}
