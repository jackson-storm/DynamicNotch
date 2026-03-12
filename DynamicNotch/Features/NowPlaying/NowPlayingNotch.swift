import SwiftUI
import AppKit

struct NowPlayingMinimalNotchContent: NotchContentProtocol {
    let id = "nowPlaying.minimal"
    let nowPlayingViewModel: NowPlayingViewModel

    var priority: Int { 81 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 80, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NowPlayingMinimalNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
}

struct NowPlayingExpandedNotchContent: NotchContentProtocol {
    let id = "nowPlaying.expanded"
    let nowPlayingViewModel: NowPlayingViewModel

    var priority: Int { 80 }
    var offsetYTransition: CGFloat { -72 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 250, height: baseHeight + 150)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(NowPlayingExpandedNotchView(nowPlayingViewModel: nowPlayingViewModel))
    }
}

private struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
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
        
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            HStack {
                ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 20, height: 20, cornerRadius: 5)
                Spacer()
                EqualizerView(isPlaying: snapshot.isPlaying, date: context.date, height: 10)
            }
            .padding(.horizontal, 14.scaled(by: scale))
        }
    }
}

private struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel

    var body: some View {
        let snapshot = resolvedSnapshot

        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let elapsedTime = nowPlayingViewModel.snapshot != nil ?
                nowPlayingViewModel.elapsedTime(at: context.date) :
                snapshot.elapsedTime
            let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)

            HStack(spacing: 14.scaled(by: scale)) {
                ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 50, height: 50, cornerRadius: 15)

                VStack(alignment: .leading, spacing: 8.scaled(by: scale)) {
                    HStack(alignment: .center, spacing: 10.scaled(by: scale)) {
                        MarqueeText(
                            .constant(displayTitle(for: snapshot)),
                            font: .system(size: 15.scaled(by: scale), weight: .semibold),
                            nsFont: .headline,
                            textColor: .white.opacity(0.95),
                            backgroundColor: .clear,
                            minDuration: 0.5,
                            frameWidth: 198.scaled(by: scale)
                        )

                        Spacer(minLength: 0)

                        EqualizerView(
                            isPlaying: snapshot.isPlaying,
                            date: context.date,
                            height: 18
                        )
                    }

                    Text(displayArtist(for: snapshot))
                        .font(.system(size: 13.scaled(by: scale), weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)

                    Text(displayAlbum(for: snapshot))
                        .font(.system(size: 12.scaled(by: scale), weight: .regular))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 4.scaled(by: scale)) {
                        PlayerProgressBar(progress: progress)

                        HStack {
                            Text(formattedTime(elapsedTime))
                            Spacer()
                            Text(snapshot.duration > 0 ? formattedTime(snapshot.duration) : "LIVE")
                        }
                        .font(.system(size: 10.scaled(by: scale), weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    }

                    HStack(spacing: 10.scaled(by: scale)) {
                        PlayerControlButton(systemImage: "backward.fill") {
                            nowPlayingViewModel.previousTrack()
                        }

                        PlayerControlButton(
                            systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                            isPrimary: true
                        ) {
                            nowPlayingViewModel.togglePlayPause()
                        }

                        PlayerControlButton(systemImage: "forward.fill") {
                            nowPlayingViewModel.nextTrack()
                        }

                        Spacer(minLength: 0)

                        Text(playbackStatusLabel(for: snapshot))
                            .font(.system(size: 11.scaled(by: scale), weight: .semibold))
                            .foregroundStyle(playbackStatusColor(for: snapshot))
                    }
                }
            }
            .padding(.horizontal, 28.scaled(by: scale))
            .padding(.vertical, 14.scaled(by: scale))
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

    private func playbackStatusLabel(for snapshot: NowPlayingSnapshot) -> String {
        if nowPlayingViewModel.snapshot == nil {
            return "Preview"
        }

        return snapshot.isPlaying ? "Playing" : "Paused"
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
    @Environment(\.notchScale) var scale
    
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
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.62, blue: 0.27),
                                Color(red: 0.28, green: 0.75, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 24.scaled(by: scale), weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
            }
        }
        .frame(width: width.scaled(by: scale), height: height.scaled(by: scale))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

private struct EqualizerView: View {
    @Environment(\.notchScale) var scale

    let isPlaying: Bool
    let date: Date
    let height: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 3.scaled(by: scale)) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.72, blue: 0.31),
                                Color(red: 0.37, green: 0.84, blue: 0.8)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4.scaled(by: scale),
                        height: barHeight(for: index)
                    )
            }
        }
        .frame(height: height.scaled(by: scale), alignment: .bottom)
        .opacity(isPlaying ? 1 : 0.55)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let minHeight = 4.scaled(by: scale)
        let maxHeight = 18.scaled(by: scale)

        guard isPlaying else {
            let restingHeights: [CGFloat] = [0.45, 0.7, 0.95, 0.62]
            return minHeight + ((maxHeight - minHeight) * restingHeights[index])
        }

        let phaseOffsets = [0.0, 0.9, 1.8, 2.7]
        let wave = (sin(date.timeIntervalSinceReferenceDate * 7 + phaseOffsets[index]) + 1) / 2
        return minHeight + ((maxHeight - minHeight) * wave)
    }
}

private struct PlayerProgressBar: View {
    let progress: CGFloat

    var body: some View {
        Capsule(style: .continuous)
            .fill(.white.opacity(0.08))
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.66, blue: 0.25),
                                    Color(red: 0.35, green: 0.82, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * progress, 6))
                }
            }
    }
}

private struct PlayerControlButton: View {
    @Environment(\.notchScale) var scale

    let systemImage: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: (isPrimary ? 14 : 12).scaled(by: scale), weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .frame(
                    width: (isPrimary ? 34 : 28).scaled(by: scale),
                    height: (isPrimary ? 34 : 28).scaled(by: scale)
                )
                .background(
                    Circle()
                        .fill(.white.opacity(isPrimary ? 0.14 : 0.07))
                )
                .overlay {
                    Circle()
                        .stroke(.white.opacity(isPrimary ? 0.18 : 0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
