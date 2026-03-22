import SwiftUI
internal import AppKit

struct NowPlayingNotchContent: NotchContentProtocol {
    let id = "nowPlaying"
    let nowPlayingViewModel: NowPlayingViewModel
    
    var priority: Int { 81 }
    var isExpandable: Bool { true }
    var strokeColor: Color { Color(nsColor: nowPlayingViewModel.artworkPalette.equalizerBaseColor.withAlphaComponent(0.35)) }
    
    var offsetXTransition: CGFloat { -100 }
    var expandedOffsetXTransition: CGFloat { -100 }
    var expandedOffsetYTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 160)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 34, bottom: 44)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NowPlayingMinimalNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(NowPlayingExpandedNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
}

private struct NowPlayingMinimalNotchView: View {
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
        
        TimelineView(.periodic(from: .now, by: nowPlayingAnimationTick)) { context in
            HStack {
                ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 24, height: 24, cornerRadius: 5)
                Spacer()
                EqualizerView(
                    isPlaying: snapshot.isPlaying,
                    palette: nowPlayingViewModel.artworkPalette,
                    trackSeed: snapshot.waveSeed,
                    date: context.date,
                    width: 2,
                    height: 2
                )
            }
            .padding(.horizontal, 14.scaled(by: scale))
        }
    }
}

struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @State private var scrubProgress: CGFloat?
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Start playback to see live metadata",
            album: "Debug Preview",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot
        
        TimelineView(.periodic(from: .now, by: nowPlayingAnimationTick)) { context in
            let elapsedTime = nowPlayingViewModel.snapshot != nil ?
            nowPlayingViewModel.elapsedTime(at: context.date) :
            snapshot.elapsedTime
            let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)
            let displayedProgress = min(max(scrubProgress ?? progress, 0), 1)
            let displayedElapsedTime = snapshot.duration > 0 ?
            TimeInterval(displayedProgress) * snapshot.duration :
            elapsedTime
            
            VStack {
                Spacer()
                
                HStack(spacing: 15) {
                    ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 60, height: 60, cornerRadius: 10)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 10) {
                            MarqueeText(
                                .constant(displayTitle(for: snapshot)),
                                font: .system(size: 16, weight: .medium),
                                nsFont: .headline,
                                textColor: .white.opacity(0.8),
                                backgroundColor: .clear,
                                minDuration: 2.0,
                                frameWidth: 170.scaled(by: scale)
                            )
                            
                            Spacer(minLength: 0)
                            
                            EqualizerView(
                                isPlaying: snapshot.isPlaying,
                                palette: nowPlayingViewModel.artworkPalette,
                                trackSeed: snapshot.waveSeed,
                                date: context.date,
                                width: 2.7,
                                height: 3.7
                            )
                        }
                        
                        MarqueeText(
                            .constant(displayArtist(for: snapshot)),
                            font: .system(size: 14),
                            nsFont: .headline,
                            textColor: .white.opacity(0.4),
                            backgroundColor: .clear,
                            minDuration: 3.0,
                            frameWidth: 170.scaled(by: scale)
                        )
                    }
                }
                Spacer()
                
                HStack(spacing: 10) {
                    Text(formattedTime(displayedElapsedTime))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    PlayerProgressBar(
                        progress: displayedProgress,
                        isInteractive: snapshot.duration > 0,
                        onScrubChanged: { newProgress in
                            scrubProgress = newProgress
                        },
                        onScrubEnded: { newProgress in
                            nowPlayingViewModel.seek(to: snapshot.duration * TimeInterval(newProgress))
                            scrubProgress = nil
                        }
                    )
                    
                    Text(snapshot.duration > 0 ? formattedTime(snapshot.duration) : "LIVE")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                HStack(spacing: 25) {
                    PlayerControlButton(
                        systemImage: "backward.fill",
                        fontSize: 22,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.previousTrack()
                    }
                    
                    PlayerControlButton(
                        systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                        fontSize: 32,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.togglePlayPause()
                    }
                    
                    PlayerControlButton(
                        systemImage: "forward.fill",
                        fontSize: 22,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.nextTrack()
                    }
                }
            }
            .padding(.horizontal, 55)
            .padding(.top, 25)
            .padding(.bottom, 15)
        }
    }
    
    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.title.trimmed.isEmpty ? "Unknown Track" : snapshot.title
    }
    
    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.artist.trimmed.isEmpty ? "Unknown Artist" : snapshot.artist
    }
    
    private func displayAlbum(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.album.trimmed.isEmpty ? "Unknown Album" : snapshot.album
    }
    
    private func progressValue(elapsedTime: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 0 }
        return min(max(CGFloat(elapsedTime / duration), 0), 1)
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }
        
        let totalSeconds = max(0, Int(time.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func playbackStatusColor(for snapshot: NowPlayingSnapshot) -> Color {
        if nowPlayingViewModel.snapshot == nil {
            return .white.opacity(0.48)
        }
        
        return snapshot.isPlaying ?
        Color(red: 0.97, green: 0.73, blue: 0.32) :
            .white.opacity(0.48)
    }
}

private struct ArtworkView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
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
    }
}

private struct EqualizerView: View {
    private struct SeededGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }

        mutating func nextUnit() -> Double {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            value = value ^ (value >> 31)
            return Double(value & 0x1FFFFFFFFFFFFF) / Double(0x1FFFFFFFFFFFFF)
        }

        mutating func next(in range: ClosedRange<Double>) -> Double {
            range.lowerBound + (nextUnit() * (range.upperBound - range.lowerBound))
        }
    }

    private struct BarProfile {
        let restLevel: CGFloat
        let floorLevel: CGFloat
        let amplitude: CGFloat
        let primaryFrequency: Double
        let primaryPhase: Double
        let secondaryFrequency: Double
        let secondaryPhase: Double
        let accentFrequency: Double
        let accentPhase: Double
        let driftFrequency: Double
        let driftPhase: Double
        let pulseFrequency: Double
        let pulsePhase: Double
    }

    let isPlaying: Bool
    let palette: NowPlayingArtworkPalette
    let trackSeed: UInt64
    let date: Date
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        let profiles = makeProfiles()

        HStack(alignment: .center, spacing: max(width, 2)) {
            ForEach(Array(profiles.indices), id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.equalizerGradient)
                    .frame(width: width, height: barHeight(for: profiles[index], index: index))
                    .animation(.linear(duration: nowPlayingAnimationTick * 1.15), value: date)
            }
        }
        .frame(height: maxHeight, alignment: .center)
        .opacity(isPlaying ? 1 : 0.55)
    }

    private func barHeight(for profile: BarProfile, index: Int) -> CGFloat {
        let dynamicRange = maxHeight - minHeight

        guard isPlaying else {
            return pausedBarHeight(for: index)
        }

        let progress = waveProgress(for: profile)
        let resolvedLevel = profile.floorLevel + (progress * profile.amplitude)
        return minHeight + (dynamicRange * min(max(resolvedLevel, 0), 1))
    }

    private var minHeight: CGFloat {
        max(height * 0.95, 3)
    }

    private var maxHeight: CGFloat {
        max(height * 4.8, minHeight + 10)
    }

    private func waveProgress(for profile: BarProfile) -> CGFloat {
        let time = date.timeIntervalSinceReferenceDate

        let primary = sin((time * profile.primaryFrequency) + profile.primaryPhase) * 0.48
        let secondary = sin((time * profile.secondaryFrequency) + profile.secondaryPhase) * 0.24
        let accent = cos((time * profile.accentFrequency) + profile.accentPhase) * 0.14
        let drift = ((sin((time * profile.driftFrequency) + profile.driftPhase) + 1) / 2) * 0.28
        let pulse = max(0, sin((time * profile.pulseFrequency) + profile.pulsePhase)) * 0.24

        let combined = primary + secondary + accent
        let normalized = (combined + 1) / 2
        let energized = min(max(normalized + drift + pulse, 0), 1)

        // Keep the motion expressive but lower the overall peaks.
        return pow(CGFloat(energized), 0.72)
    }

    private func pausedBarHeight(for index: Int) -> CGFloat {
        let pausedLevels: [CGFloat] = [0.82, 0.98, 1.16, 0.98, 0.82]
        let baseDotSize = max(width + 0.8, height * 0.9, 2.8)
        return baseDotSize * pausedLevels[index]
    }

    private func makeProfiles() -> [BarProfile] {
        var generator = SeededGenerator(seed: trackSeed)

        return Array(0..<5).map { index in
            let barOffset = Double(index) * 0.13

            return BarProfile(
                restLevel: CGFloat(generator.next(in: 0.08...0.92)),
                floorLevel: CGFloat(generator.next(in: 0.08...0.22)),
                amplitude: CGFloat(generator.next(in: 0.64...0.88)),
                primaryFrequency: generator.next(in: 6.1...8.8) + (barOffset * 1.2),
                primaryPhase: generator.next(in: 0...(Double.pi * 2)),
                secondaryFrequency: generator.next(in: 3.4...5.6) + (barOffset * 0.95),
                secondaryPhase: generator.next(in: 0...(Double.pi * 2)),
                accentFrequency: generator.next(in: 10.8...15.6) + (barOffset * 1.1),
                accentPhase: generator.next(in: 0...(Double.pi * 2)),
                driftFrequency: generator.next(in: 1.2...2.3),
                driftPhase: generator.next(in: 0...(Double.pi * 2)),
                pulseFrequency: generator.next(in: 13.2...19.0) + (barOffset * 1.45),
                pulsePhase: generator.next(in: 0...(Double.pi * 2))
            )
        }
    }
}

private let nowPlayingAnimationTick: TimeInterval = 1.0 / 10.0

private func stableFNV1A64Hash(of value: String) -> UInt64 {
    let offsetBasis: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x100000001b3

    return value.utf8.reduce(offsetBasis) { partialResult, byte in
        (partialResult ^ UInt64(byte)) &* prime
    }
}

private struct PlayerProgressBar: View {
    let progress: CGFloat
    let isInteractive: Bool
    let onScrubChanged: (CGFloat) -> Void
    let onScrubEnded: (CGFloat) -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let resolvedProgress = min(max(progress, 0), 1)
            let trackHeight: CGFloat = 7
            let filledWidth = proxy.size.width * resolvedProgress

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.15))
                    .frame(height: trackHeight)

                Capsule(style: .continuous)
                    .fill(.white.opacity(0.5))
                    .frame(width: filledWidth, height: trackHeight)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isInteractive else { return }
                        onScrubChanged(progress(at: value.location.x, in: proxy.size.width))
                    }
                    .onEnded { value in
                        guard isInteractive else { return }
                        onScrubEnded(progress(at: value.location.x, in: proxy.size.width))
                    }
            )
        }
        .frame(height: 18)
    }

    private func progress(at locationX: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        return min(max(locationX / width, 0), 1)
    }
}

private struct PlayerControlButton: View {
    @Environment(\.notchScale) var scale
    
    let systemImage: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(PressedButtonStyle(width: width, height: height))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension NowPlayingSnapshot {
    var waveSeed: UInt64 {
        let trackIdentity = [
            title.trimmed,
            artist.trimmed,
            album.trimmed,
            String(Int(duration.rounded())),
            String(artworkData?.count ?? 0)
        ].joined(separator: "|")

        return stableFNV1A64Hash(of: trackIdentity)
    }
}
