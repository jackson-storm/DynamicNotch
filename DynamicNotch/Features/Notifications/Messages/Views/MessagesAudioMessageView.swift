import SwiftUI

struct MessagesAudioMessageView: View {
    @StateObject private var player: MessagesAudioPlayer
    @State private var scrubProgress: CGFloat?

    private let onPlaybackStateChanged: (Bool) -> Void

    init(fileURL: URL, duration: TimeInterval?, onPlaybackStateChanged: @escaping (Bool) -> Void = { _ in }) {
        _player = StateObject(wrappedValue: MessagesAudioPlayer(fileURL: fileURL, duration: duration))
        self.onPlaybackStateChanged = onPlaybackStateChanged
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !player.isPlaying)) { _ in
            audioContent(progress: scrubProgress ?? player.progress)
        }
        .onChange(of: player.isPlaying) { _, isPlaying in
            onPlaybackStateChanged(isPlaying)
        }
        .onDisappear {
            player.stop()
            onPlaybackStateChanged(false)
        }
    }

    private func audioContent(progress: CGFloat) -> some View {
        HStack(spacing: 9) {
            PlayerControlButton(
                systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                fontSize: 15,
                width: 30,
                height: 30,
                feedbackStyle: .playPause
            ) {
                player.togglePlayback()
            }
            .opacity(player.isAvailable ? 1 : 0.5)
            .disabled(!player.isAvailable)

            MessagesAudioWaveformView(
                samples: player.waveform,
                progress: progress,
                isInteractive: player.isAvailable,
                onScrubChanged: { newProgress in
                    scrubProgress = newProgress
                },
                onScrubEnded: { newProgress in
                    player.seek(to: newProgress)
                    scrubProgress = nil
                }
            )
            .frame(minWidth: 110, maxWidth: 180)
            .frame(height: 20)

            Spacer()

            Text(formattedTime(player.duration))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.7))
                .frame(minWidth: 32, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .padding(.trailing, 10)
        .padding(.leading, 7)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.1))
        }
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }

        let totalSeconds = max(0, Int(time.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct MessagesAudioWaveformView: View {
    let samples: [CGFloat]
    let progress: CGFloat
    let isInteractive: Bool
    let onScrubChanged: (CGFloat) -> Void
    let onScrubEnded: (CGFloat) -> Void

    private var displayedSamples: [CGFloat] {
        samples.isEmpty ? Array(repeating: 0.18, count: 36) : samples
    }

    var body: some View {
        GeometryReader { proxy in
            let resolvedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                MessagesAudioWaveformBars(samples: displayedSamples, color: .white.opacity(0.2))
                
                MessagesAudioWaveformBars(samples: displayedSamples, color: .white.opacity(0.88))
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: proxy.size.width * resolvedProgress)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }

    private func progress(at locationX: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }

        return min(max(locationX / width, 0), 1)
    }
}

private struct MessagesAudioWaveformBars: View {
    let samples: [CGFloat]
    let color: Color

    private let spacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let barWidth = resolvedBarWidth(in: proxy.size.width)

            HStack(alignment: .center, spacing: spacing) {
                ForEach(samples.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(color)
                        .frame(width: barWidth, height: resolvedBarHeight(samples[index], availableHeight: proxy.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func resolvedBarWidth(in availableWidth: CGFloat) -> CGFloat {
        guard !samples.isEmpty else { return 1 }

        let totalSpacing = spacing * CGFloat(max(samples.count - 1, 0))
        return max((availableWidth - totalSpacing) / CGFloat(samples.count), 1)
    }

    private func resolvedBarHeight(_ sample: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let normalizedSample = min(max(sample, 0), 1)

        return max(availableHeight * normalizedSample, 2.5)
    }
}
