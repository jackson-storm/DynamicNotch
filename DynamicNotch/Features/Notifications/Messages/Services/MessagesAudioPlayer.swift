import AVFoundation
import Combine
import Foundation
import OSLog

@MainActor
final class MessagesAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published private(set) var isPlaying = false
    @Published private(set) var isAvailable = false
    @Published private(set) var duration: TimeInterval
    @Published private(set) var waveform: [CGFloat] = [
        0.18, 0.24, 0.30, 0.42, 0.58, 0.76, 0.62, 0.86,
        0.48, 0.70, 0.92, 0.56, 0.38, 0.64, 0.80, 0.74,
        0.88, 0.46, 0.68, 0.82, 0.54, 0.90, 0.72, 0.60,
        0.84, 0.48, 0.76, 0.66, 0.52, 0.78, 0.58, 0.44,
        0.34, 0.28, 0.22, 0.18
    ]

    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    var progress: CGFloat {
        guard duration > 0 else { return 0 }

        return min(max(CGFloat(currentTime / duration), 0), 1)
    }

    private static weak var activePlayer: MessagesAudioPlayer?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesAudioPlayer")
    private let fileURL: URL
    private let waveformLoader = MessagesAudioWaveformLoader()

    private var audioPlayer: AVAudioPlayer?
    private var preparationTask: Task<Void, Never>?
    private var waveformTask: Task<Void, Never>?
    private var isStartingPlayback = false
    private var playbackRequestID = 0

    init(fileURL: URL, duration: TimeInterval?) {
        self.fileURL = fileURL
        self.duration = max(duration ?? 0, 0)

        super.init()

        preparePlayer()
        loadWaveform()
    }

    deinit {
        preparationTask?.cancel()
        waveformTask?.cancel()

        if let audioPlayer {
            Self.release(audioPlayer)
        }
    }

    func togglePlayback() {
        if isPlaying || isStartingPlayback {
            pause()
        } else {
            play()
        }
    }

    func seek(to progress: CGFloat) {
        guard let audioPlayer, duration > 0 else { return }

        let normalizedProgress = min(max(progress, 0), 1)
        let maximumTime = max(duration - 0.01, 0)
        let requestedTime = duration * TimeInterval(normalizedProgress)

        audioPlayer.currentTime = min(requestedTime, maximumTime)
    }

    func stop() {
        playbackRequestID += 1
        isStartingPlayback = false
        isPlaying = false

        if Self.activePlayer === self {
            Self.activePlayer = nil
        }

        guard let audioPlayer else { return }

        audioPlayer.currentTime = 0

        let preparedPlayer = MessagesPreparedAudioPlayer(player: audioPlayer)

        MessagesAudioPlaybackExecutor.queue.async {
            preparedPlayer.player.pause()
            preparedPlayer.player.currentTime = 0
        }
    }

    private func preparePlayer() {
        preparationTask?.cancel()

        let fileURL = fileURL

        preparationTask = Task { [weak self] in
            do {
                let preparedPlayer = try await Task.detached(priority: .userInitiated) {
                    try Task.checkCancellation()

                    let player = try AVAudioPlayer(contentsOf: fileURL)
                    player.prepareToPlay()

                    try Task.checkCancellation()

                    return MessagesPreparedAudioPlayer(player: player)
                }.value

                let player = preparedPlayer.player

                guard let self, !Task.isCancelled else {
                    Self.release(player)
                    return
                }

                player.delegate = self
                audioPlayer = player
                isAvailable = true

                if player.duration.isFinite, player.duration > 0 {
                    duration = player.duration
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                self?.logger.error("Could not prepare Messages audio attachment: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func play() {
        guard let audioPlayer else { return }

        if let activePlayer = Self.activePlayer, activePlayer !== self {
            activePlayer.pause()
        }

        let shouldRestart = audioPlayer.currentTime >= duration - 0.05
        let preparedPlayer = MessagesPreparedAudioPlayer(player: audioPlayer)

        playbackRequestID += 1

        let requestID = playbackRequestID

        isStartingPlayback = true
        Self.activePlayer = self

        MessagesAudioPlaybackExecutor.queue.async {
            if shouldRestart {
                preparedPlayer.player.currentTime = 0
            }

            let didStart = preparedPlayer.player.play()

            Task { @MainActor [weak self] in
                guard let self,
                      self.audioPlayer === preparedPlayer.player,
                      self.playbackRequestID == requestID else {
                    return
                }

                self.isStartingPlayback = false

                guard didStart else {
                    self.isPlaying = false

                    if Self.activePlayer === self {
                        Self.activePlayer = nil
                    }

                    self.logger.error("Could not start Messages audio playback")
                    return
                }

                self.isPlaying = true
            }
        }
    }

    private func pause() {
        playbackRequestID += 1
        isStartingPlayback = false
        isPlaying = false

        if Self.activePlayer === self {
            Self.activePlayer = nil
        }

        guard let audioPlayer else { return }

        let preparedPlayer = MessagesPreparedAudioPlayer(player: audioPlayer)

        MessagesAudioPlaybackExecutor.queue.async {
            preparedPlayer.player.pause()
        }
    }

    private func loadWaveform() {
        waveformTask?.cancel()

        waveformTask = Task { [weak self] in
            guard let self else { return }

            do {
                let samples = try await waveformLoader.samples(from: fileURL, count: 36)

                guard !Task.isCancelled, !samples.isEmpty else { return }

                waveform = samples
            } catch is CancellationError {
                return
            } catch {
                logger.error("Could not load Messages audio waveform: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private nonisolated static func release(_ player: AVAudioPlayer) {
        let preparedPlayer = MessagesPreparedAudioPlayer(player: player)

        MessagesAudioPlaybackExecutor.queue.async {
            preparedPlayer.player.stop()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.audioPlayer === player else { return }

            self.playbackRequestID += 1
            self.isStartingPlayback = false
            self.isPlaying = false

            if Self.activePlayer === self {
                Self.activePlayer = nil
            }
        }
    }
}

private struct MessagesPreparedAudioPlayer: @unchecked Sendable {
    let player: AVAudioPlayer
}

private enum MessagesAudioPlaybackExecutor {
    nonisolated static let queue = DispatchQueue(label: "com.dynamicnotch.messages-audio-playback", qos: .userInitiated)
}

private actor MessagesAudioWaveformLoader {

    func samples(from fileURL: URL, count: Int) throws -> [CGFloat] {
        guard count > 0 else { return [] }

        let audioFile = try AVAudioFile(forReading: fileURL, commonFormat: .pcmFormatFloat32, interleaved: false)
        let format = audioFile.processingFormat
        let frameCapacity: AVAudioFrameCount = 4_096

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            throw MessagesAudioWaveformError.couldNotCreateBuffer
        }

        var peaks: [Float] = []

        while audioFile.framePosition < audioFile.length {
            try Task.checkCancellation()

            let remainingFrames = audioFile.length - audioFile.framePosition
            let frameCount = AVAudioFrameCount(min(Int64(frameCapacity), remainingFrames))

            try audioFile.read(into: buffer, frameCount: frameCount)

            guard buffer.frameLength > 0 else { break }

            if let peak = peak(from: buffer) {
                peaks.append(peak)
            }
        }

        return normalizedSamples(from: peaks, count: count)
    }

    private func peak(from buffer: AVAudioPCMBuffer) -> Float? {
        guard let channelData = buffer.floatChannelData else { return nil }

        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)

        guard channelCount > 0, frameCount > 0 else { return nil }

        var peak: Float = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]

            for frame in 0..<frameCount {
                peak = max(peak, abs(samples[frame]))
            }
        }

        return peak
    }

    private func normalizedSamples(from peaks: [Float], count: Int) -> [CGFloat] {
        guard !peaks.isEmpty else { return [] }

        let sampledPeaks: [Float]

        if peaks.count >= count {
            sampledPeaks = (0..<count).map { index in
                let start = index * peaks.count / count
                let end = max(start + 1, (index + 1) * peaks.count / count)

                return peaks[start..<min(end, peaks.count)].max() ?? 0
            }
        } else if peaks.count == 1 {
            sampledPeaks = Array(repeating: peaks[0], count: count)
        } else {
            sampledPeaks = (0..<count).map { index in
                let position = Double(index) * Double(peaks.count - 1) / Double(max(count - 1, 1))
                let lowerIndex = Int(position.rounded(.down))
                let upperIndex = min(lowerIndex + 1, peaks.count - 1)
                let fraction = Float(position - Double(lowerIndex))

                return peaks[lowerIndex] + ((peaks[upperIndex] - peaks[lowerIndex]) * fraction)
            }
        }

        let maximum = max(sampledPeaks.max() ?? 0, 0.001)

        return sampledPeaks.map { peak in
            max(CGFloat(peak / maximum), 0.14)
        }
    }
}

private enum MessagesAudioWaveformError: LocalizedError {
    case couldNotCreateBuffer

    var errorDescription: String? {
        switch self {
        case .couldNotCreateBuffer:
            "Could not create an audio waveform buffer"
        }
    }
}
