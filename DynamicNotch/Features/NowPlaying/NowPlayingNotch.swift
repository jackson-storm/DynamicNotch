import SwiftUI
internal import AppKit

struct NowPlayingAppearanceOptions {
    let showsFavoriteButton: Bool
    let showsOutputDeviceButton: Bool
    let usesArtworkTint: Bool
    let usesArtworkStrokeTint: Bool
}

struct NowPlayingNotchContent: NotchContentProtocol {
    let id = "nowPlaying"
    let nowPlayingViewModel: NowPlayingViewModel
    let settings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    
    var priority: Int { 81 }
    var isExpandable: Bool { true }
    
    var offsetXTransition: CGFloat { 0 }
    var expandedOffsetXTransition: CGFloat { -100 }
    var expandedOffsetYTransition: CGFloat { -90 }

    var strokeColor: Color {
        guard settings.isNowPlayingArtworkStrokeEnabled,
              applicationSettings.isDefaultActivityStrokeEnabled == false else {
            return .white.opacity(0.2)
        }

        return Color(nsColor: nowPlayingViewModel.artworkPalette.equalizerBaseColor).opacity(0.4)
    }
    
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
        AnyView(
            NowPlayingMinimalNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settings
            )
        )
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            NowPlayingExpandedNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settings,
                applicationSettings: applicationSettings
            )
        )
    }
}

private struct NowPlayingMinimalNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
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
                    mode: settings.nowPlayingEqualizerMode,
                    palette: nowPlayingViewModel.artworkPalette,
                    trackSeed: snapshot.waveSeed,
                    audioLevels: nowPlayingViewModel.audioReactiveLevels,
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
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
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
            let appearance = settings.resolvedNowPlayingAppearanceOptions(
                isDefaultActivityStrokeEnabled: applicationSettings.isDefaultActivityStrokeEnabled
            )
            
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
                                mode: settings.nowPlayingEqualizerMode,
                                palette: nowPlayingViewModel.artworkPalette,
                                trackSeed: snapshot.waveSeed,
                                audioLevels: nowPlayingViewModel.audioReactiveLevels,
                                date: context.date,
                                width: 2.7,
                                height: 3.7
                            )
                        }
                        
                        MarqueeText(
                            .constant(displayArtist(for: snapshot)),
                            font: .system(size: 14),
                            nsFont: .headline,
                            textColor: .white.opacity(0.5),
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
                        .foregroundStyle(progressTimeColor(isPrimary: true, appearance: appearance))
                    
                    PlayerProgressBar(
                        progress: displayedProgress,
                        isInteractive: snapshot.duration > 0,
                        tintGradient: appearance.usesArtworkTint ? nowPlayingViewModel.artworkPalette.equalizerGradient : nil,
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
                        .foregroundStyle(progressTimeColor(isPrimary: false, appearance: appearance))
                }
                
                Spacer()
                
                ZStack {
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

                    HStack {
                        if appearance.showsFavoriteButton {
                            FavoriteTrackButton(
                                nowPlayingViewModel: nowPlayingViewModel,
                                width: 42,
                                height: 42,
                                fontSize: 21
                            )
                        }

                        Spacer()

                        if appearance.showsOutputDeviceButton {
                            AudioOutputRoutePickerButton(
                                nowPlayingViewModel: nowPlayingViewModel,
                                width: 42,
                                height: 42,
                                fontSize: 21
                            )
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .frame(maxWidth: .infinity)
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

    private func progressTimeColor(isPrimary: Bool, appearance: NowPlayingAppearanceOptions) -> Color {
        guard appearance.usesArtworkTint else {
            return .white.opacity(0.4)
        }

        let nsColor = isPrimary ?
        nowPlayingViewModel.artworkPalette.equalizerHighlightColor :
        nowPlayingViewModel.artworkPalette.equalizerBaseColor

        return Color(nsColor: nsColor)
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

        mutating func nextUInt64() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            return value ^ (value >> 31)
        }

        mutating func nextUnit() -> Double {
            Double(nextUInt64() & 0x1FFFFFFFFFFFFF) / Double(0x1FFFFFFFFFFFFF)
        }

        mutating func next(in range: ClosedRange<Double>) -> Double {
            range.lowerBound + (nextUnit() * (range.upperBound - range.lowerBound))
        }
    }

    private struct BarProfile {
        let restLevel: CGFloat
        let floorLevel: CGFloat
        let amplitude: CGFloat
        let reactiveWeight: CGFloat
        let reactiveBias: CGFloat
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
        let flutterFrequency: Double
        let flutterPhase: Double
        let chaosFrequency: Double
        let chaosAmount: CGFloat
        let chaosSeed: UInt64
        let dropFrequency: Double
        let dropPhase: Double
    }

    let isPlaying: Bool
    let mode: NowPlayingEqualizerMode
    let palette: NowPlayingArtworkPalette
    let trackSeed: UInt64
    let audioLevels: [CGFloat]
    let date: Date
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        let profiles = profilesForCurrentMode()

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

        switch mode {
        case .classic:
            let progress = waveProgress(for: profile)
            let resolvedLevel = profile.floorLevel + (progress * profile.amplitude)
            return minHeight + (dynamicRange * min(max(resolvedLevel, 0), 1))
        case .audioReactive:
            return reactiveBarHeight(for: profile, index: index, dynamicRange: dynamicRange)
        }
    }

    private var minHeight: CGFloat {
        max(height * 0.58, 2.4)
    }

    private var maxHeight: CGFloat {
        max(height * 5.9, minHeight + 12)
    }

    private func waveProgress(for profile: BarProfile) -> CGFloat {
        let time = date.timeIntervalSinceReferenceDate

        let primary = sin((time * profile.primaryFrequency) + profile.primaryPhase) * 0.36
        let secondary = sin((time * profile.secondaryFrequency) + profile.secondaryPhase) * 0.2
        let accent = cos((time * profile.accentFrequency) + profile.accentPhase) * 0.1
        let drift = sin((time * profile.driftFrequency) + profile.driftPhase) * 0.18
        let flutter = sin((time * profile.flutterFrequency) + profile.flutterPhase) * 0.04
        let chaotic = (chaoticProgress(for: profile, time: time) - 0.5) * profile.chaosAmount
        let pulse = pow(max(0, sin((time * profile.pulseFrequency) + profile.pulsePhase)), 1.2) * 0.2
        let drop = pow(max(0, cos((time * profile.dropFrequency) + profile.dropPhase)), 1.45) * 0.12

        let baseLevel = profile.restLevel + CGFloat(primary + secondary + accent + drift + flutter)
        let energized = min(max(baseLevel + chaotic + CGFloat(pulse) - CGFloat(drop), 0), 1)

        return pow(energized, 0.94)
    }

    private func reactiveWaveProgress(for profile: BarProfile, index: Int) -> CGFloat {
        let time = date.timeIntervalSinceReferenceDate
        let centerBand = audioBandLevel(at: index)
        let previousBand = audioBandLevel(at: index - 1)
        let nextBand = audioBandLevel(at: index + 1)
        let neighborAverage = (previousBand + nextBand) * 0.5
        let bandSpread = abs(previousBand - nextBand)
        let blendedBand = (centerBand * 0.6) + (neighborAverage * 0.4)
        let crest = max(centerBand - neighborAverage, 0)
        let envelope = pow(blendedBand, 0.8)
        let drive = min(max((centerBand * 0.78) + (crest * 0.55) + (bandSpread * 0.24), 0), 1)
        let travelPhase = Double(index) * 0.52

        let sway = sin((time * profile.driftFrequency) + profile.driftPhase + travelPhase) *
            (0.025 + (drive * 0.03))
        let ripple = sin((time * (profile.secondaryFrequency * 0.72)) + profile.secondaryPhase + (travelPhase * 1.4)) *
            (0.015 + (drive * 0.03))
        let flutter = sin((time * (profile.flutterFrequency * 0.5)) + profile.flutterPhase - travelPhase) *
            (0.006 + (bandSpread * 0.02))
        let pulse = pow(
            max(0, sin((time * (profile.pulseFrequency * 0.4)) + profile.pulsePhase + travelPhase)),
            1.35
        ) * (0.02 + (drive * 0.06))
        let bounce = max(
            0,
            sin((time * (profile.accentFrequency * 0.42)) + profile.accentPhase + (travelPhase * 0.6))
        ) * (0.008 + (drive * 0.026))
        let thrust = pow(drive, index == 0 ? 0.72 : 0.8) * (0.035 + (centerBand * 0.075))
        let crestLift = pow(crest, 0.82) * (0.045 + (centerBand * 0.075))
        let chaos = (chaoticProgress(for: profile, time: time) - 0.5) * (0.015 + (drive * 0.03))
        let settle = max(
            0,
            cos((time * (profile.dropFrequency * 0.34)) + profile.dropPhase - travelPhase)
        ) * (0.01 + ((1 - centerBand) * 0.025))

        let reactiveLevel =
            profile.reactiveBias +
            (envelope * profile.reactiveWeight) +
            thrust +
            crestLift +
            CGFloat(sway + ripple + flutter + pulse + bounce + chaos - settle)

        return min(max(reactiveLevel, 0), 1)
    }

    private func reactiveBarHeight(for profile: BarProfile, index: Int, dynamicRange: CGFloat) -> CGFloat {
        let centerBand = audioBandLevel(at: index)
        let neighborAverage = (audioBandLevel(at: index - 1) + audioBandLevel(at: index + 1)) * 0.5
        let gateSource = index == 0 ? centerBand : max(centerBand, neighborAverage * 0.58)
        let releaseThreshold = reactiveDotThreshold(for: index) * 0.54
        let dotHeight = pausedBarHeight(for: index)

        guard gateSource > releaseThreshold else {
            return dotHeight
        }

        let activation = reactiveActivationLevel(for: gateSource, index: index)
        let progress = reactiveWaveProgress(for: profile, index: index)
        let resolvedLevel = profile.floorLevel + (progress * profile.amplitude)
        let waveHeight = minHeight + (dynamicRange * min(max(resolvedLevel, 0), 1))
        let liveliness = min(max((centerBand * 0.74) + (neighborAverage * 0.26), 0), 1)
        let liftedActivation = min(max(activation + (liveliness * 0.06), 0), 1)

        return dotHeight + ((waveHeight - dotHeight) * liftedActivation)
    }

    private func reactiveDotThreshold(for index: Int) -> CGFloat {
        let thresholds: [CGFloat] = [0.12, 0.085, 0.075, 0.07, 0.065]
        let clampedIndex = min(max(index, 0), thresholds.count - 1)
        return thresholds[clampedIndex]
    }

    private func reactiveActivationLevel(for bandLevel: CGFloat, index: Int) -> CGFloat {
        let threshold = reactiveDotThreshold(for: index)
        let normalized = max((bandLevel - threshold) / max(1 - threshold, 0.001), 0)
        let responseCurves: [CGFloat] = [0.62, 0.72, 0.8, 0.84, 0.88]
        let clampedIndex = min(max(index, 0), responseCurves.count - 1)
        return min(max(pow(normalized, responseCurves[clampedIndex]), 0), 1)
    }

    private func audioBandLevel(at index: Int) -> CGFloat {
        guard !audioLevels.isEmpty else { return 0 }
        let clampedIndex = min(max(index, 0), audioLevels.count - 1)
        return min(max(audioLevels[clampedIndex], 0), 1)
    }

    private func chaoticProgress(for profile: BarProfile, time: Double) -> CGFloat {
        let scaledTime = max(time * profile.chaosFrequency, 0)
        let currentStep = UInt64(scaledTime.rounded(.down))
        let nextStep = currentStep &+ 1
        let progress = scaledTime - Double(currentStep)
        let easedProgress = progress * progress * (3 - (2 * progress))

        let currentValue = steppedUnit(seed: profile.chaosSeed, step: currentStep)
        let nextValue = steppedUnit(seed: profile.chaosSeed, step: nextStep)
        return CGFloat(currentValue + ((nextValue - currentValue) * easedProgress))
    }

    private func steppedUnit(seed: UInt64, step: UInt64) -> Double {
        var generator = SeededGenerator(seed: seed ^ (step &* 0x9E3779B97F4A7C15))
        return generator.nextUnit()
    }

    private func pausedBarHeight(for index: Int) -> CGFloat {
        let pausedLevels: [CGFloat] = [0.82, 0.98, 1.16, 0.98, 0.82]
        let baseDotSize = max(width + 0.8, height * 0.9, 2.8)
        return baseDotSize * pausedLevels[index]
    }

    private func profilesForCurrentMode() -> [BarProfile] {
        switch mode {
        case .classic:
            makeClassicProfiles()
        case .audioReactive:
            makeAudioReactiveProfiles()
        }
    }

    private func makeClassicProfiles() -> [BarProfile] {
        var generator = SeededGenerator(seed: trackSeed)

        return Array(0..<5).map { index in
            let barOffset = Double(index) * 0.13

            return BarProfile(
                restLevel: CGFloat(generator.next(in: 0.34...0.6)),
                floorLevel: CGFloat(generator.next(in: 0.02...0.12)),
                amplitude: CGFloat(generator.next(in: 0.72...0.9)),
                reactiveWeight: CGFloat(generator.next(in: 0.56...0.94)),
                reactiveBias: CGFloat(generator.next(in: 0.05...0.16)),
                primaryFrequency: generator.next(in: 4.2...6.4) + (barOffset * 0.88),
                primaryPhase: generator.next(in: 0...(Double.pi * 2)),
                secondaryFrequency: generator.next(in: 2.6...4.5) + (barOffset * 0.7),
                secondaryPhase: generator.next(in: 0...(Double.pi * 2)),
                accentFrequency: generator.next(in: 7.0...10.4) + (barOffset * 1.0),
                accentPhase: generator.next(in: 0...(Double.pi * 2)),
                driftFrequency: generator.next(in: 1.0...1.9),
                driftPhase: generator.next(in: 0...(Double.pi * 2)),
                pulseFrequency: generator.next(in: 8.2...12.6) + (barOffset * 1.08),
                pulsePhase: generator.next(in: 0...(Double.pi * 2)),
                flutterFrequency: generator.next(in: 10.4...15.0) + (barOffset * 1.22),
                flutterPhase: generator.next(in: 0...(Double.pi * 2)),
                chaosFrequency: generator.next(in: 2.0...3.8),
                chaosAmount: CGFloat(generator.next(in: 0.12...0.22)),
                chaosSeed: generator.nextUInt64(),
                dropFrequency: generator.next(in: 5.8...8.8) + (barOffset * 0.92),
                dropPhase: generator.next(in: 0...(Double.pi * 2))
            )
        }
    }

    private func makeAudioReactiveProfiles() -> [BarProfile] {
        let roles: [(rest: CGFloat, floor: CGFloat, amplitude: CGFloat, weight: CGFloat, bias: CGFloat)] = [
            (0.26, 0.02, 0.96, 0.98, 0.02), // bass
            (0.3, 0.03, 0.92, 0.88, 0.035), // low-mid
            (0.38, 0.05, 0.84, 0.76, 0.06), // mid
            (0.33, 0.04, 0.88, 0.8, 0.05), // presence
            (0.28, 0.03, 0.82, 0.7, 0.04) // highs
        ]

        return roles.enumerated().map { index, role in
            let barOffset = Double(index) * 0.11

            return BarProfile(
                restLevel: role.rest,
                floorLevel: role.floor,
                amplitude: role.amplitude,
                reactiveWeight: role.weight,
                reactiveBias: role.bias,
                primaryFrequency: 4.2 + (barOffset * 0.9),
                primaryPhase: Double(index) * 0.58,
                secondaryFrequency: 2.5 + (barOffset * 0.72),
                secondaryPhase: 0.9 + (Double(index) * 0.44),
                accentFrequency: 7.2 + (barOffset * 1.1),
                accentPhase: 1.4 + (Double(index) * 0.61),
                driftFrequency: 1.1 + (Double(index) * 0.08),
                driftPhase: 0.6 + (Double(index) * 0.33),
                pulseFrequency: 8.4 + (barOffset * 1.16),
                pulsePhase: 0.5 + (Double(index) * 0.4),
                flutterFrequency: 10.2 + (barOffset * 1.28),
                flutterPhase: 1.0 + (Double(index) * 0.47),
                chaosFrequency: 2.3 + (Double(index) * 0.22),
                chaosAmount: 0.12 + (CGFloat(index) * 0.012),
                chaosSeed: 0xA24BAED4963EE407 ^ (UInt64(index) &* 0x9E3779B97F4A7C15),
                dropFrequency: 5.9 + (barOffset * 0.94),
                dropPhase: 1.2 + (Double(index) * 0.38)
            )
        }
    }
}

private let nowPlayingAnimationTick: TimeInterval = 1.0 / 14.0

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
    let tintGradient: LinearGradient?
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

                if let tintGradient {
                    Capsule(style: .continuous)
                        .fill(tintGradient)
                        .frame(width: filledWidth, height: trackHeight)
                } else {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.5))
                        .frame(width: filledWidth, height: trackHeight)
                }

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

struct FavoriteTrackButton: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel

    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat

    var body: some View {
        Button {
            nowPlayingViewModel.toggleFavorite()
        } label: {
            Image(systemName: nowPlayingViewModel.isCurrentTrackFavorite ? "star.fill" : "star")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .buttonStyle(PressedButtonStyle(width: width, height: height))
        .disabled(!nowPlayingViewModel.canToggleFavorite)
        .opacity(nowPlayingViewModel.canToggleFavorite ? 1 : 0.45)
    }

    private var iconColor: Color {
        if nowPlayingViewModel.isCurrentTrackFavorite {
            return Color.white.opacity(0.5)
        }

        return .white.opacity(0.5)
    }
}

struct AudioOutputRoutePickerButton: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    var width: CGFloat = 42
    var height: CGFloat = 42
    var fontSize: CGFloat = 20

    var body: some View {
        Menu {
            if nowPlayingViewModel.audioOutputRoutes.isEmpty {
                Text(verbatim: "No audio outputs available")
            } else {
                ForEach(nowPlayingViewModel.audioOutputRoutes) { route in
                    Button {
                        nowPlayingViewModel.switchAudioOutput(to: route)
                    } label: {
                        routeMenuLabel(route)
                    }
                }
            }
        } label: {
            Image(systemName: currentRouteSymbolName)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .menuIndicator(.hidden)
        .buttonStyle(PressedButtonStyle(width: width, height: height))
        .onAppear {
            nowPlayingViewModel.refreshAudioOutputRoutes()
        }
    }

    private var currentRouteSymbolName: String {
        if let currentRoute = nowPlayingViewModel.currentAudioOutputRoute {
            return currentRoute.systemImageName
        }

        if let selectedRoute = nowPlayingViewModel.audioOutputRoutes.first(where: \.isCurrent) {
            return selectedRoute.systemImageName
        }

        return "airplayaudio"
    }

    private func routeMenuLabel(_ route: AudioOutputRoute) -> some View {
        HStack(spacing: 8) {
            Image(systemName: route.systemImageName)
                .frame(width: 18)

            Text(route.name)

            if route.isCurrent {
                Spacer(minLength: 12)
                Image(systemName: "checkmark")
            }
        }
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
