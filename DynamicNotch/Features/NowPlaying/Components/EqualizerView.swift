//
//  EqualizerView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct EqualizerView: View {
    let isPlaying: Bool
    let mode: NowPlayingEqualizerMode
    let palette: NowPlayingArtworkPalette
    let trackSeed: UInt64
    let audioLevels: [CGFloat]
    let date: Date
    let width: CGFloat
    let height: CGFloat
    let nowPlayingAnimationTick: TimeInterval = 1.0 / 14.0
    
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

extension NowPlayingSnapshot {
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
    
    private func stableFNV1A64Hash(of value: String) -> UInt64 {
        let offsetBasis: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3

        return value.utf8.reduce(offsetBasis) { partialResult, byte in
            (partialResult ^ UInt64(byte)) &* prime
        }
    }
}
