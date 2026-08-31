import AVFoundation
import XCTest
@testable import DynamicNotch

@MainActor
final class MessagesAudioPlayerTests: XCTestCase {

    func testMissingFileRemainsUnavailableAndDoesNotStartPlayback() async {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")

        let player = MessagesAudioPlayer(fileURL: missingURL, duration: -5)

        player.togglePlayback()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(player.isAvailable)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.duration, 0)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.progress, 0)
    }

    func testValidAudioBecomesAvailableAndUsesMeasuredDuration() async throws {
        let audioFile = try await MessagesAudioTestFile.make(duration: 1)
        let player = MessagesAudioPlayer(fileURL: audioFile.url, duration: nil)

        defer {
            player.stop()
        }

        let becameAvailable = await waitUntil {
            player.isAvailable
        }

        XCTAssertTrue(becameAvailable)

        guard becameAvailable else { return }

        XCTAssertEqual(player.duration, 1, accuracy: 0.05)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.01)
        XCTAssertEqual(player.progress, 0, accuracy: 0.01)
    }

    func testWaveformIsLoadedAndNormalized() async throws {
        let audioFile = try await MessagesAudioTestFile.make(duration: 1, containsSignal: true)
        let player = MessagesAudioPlayer(fileURL: audioFile.url, duration: nil)

        defer {
            player.stop()
        }

        let waveformWasLoaded = await waitUntil {
            (player.waveform.max() ?? 0) >= 0.99
        }

        XCTAssertTrue(waveformWasLoaded)

        guard waveformWasLoaded else { return }

        XCTAssertEqual(player.waveform.count, 36)
        XCTAssertTrue(player.waveform.allSatisfy { $0 >= 0.14 && $0 <= 1 })
        XCTAssertEqual(player.waveform.max() ?? 0, 1, accuracy: 0.001)
    }

    func testSeekClampsProgressToAvailableRange() async throws {
        let audioFile = try await MessagesAudioTestFile.make(duration: 2)
        let player = MessagesAudioPlayer(fileURL: audioFile.url, duration: nil)

        defer {
            player.stop()
        }

        let becameAvailable = await waitUntil {
            player.isAvailable
        }

        XCTAssertTrue(becameAvailable)

        guard becameAvailable else { return }

        player.seek(to: -1)

        XCTAssertEqual(player.currentTime, 0, accuracy: 0.02)
        XCTAssertEqual(player.progress, 0, accuracy: 0.01)

        player.seek(to: 2)

        XCTAssertGreaterThan(player.currentTime, player.duration - 0.05)
        XCTAssertLessThan(player.currentTime, player.duration)
        XCTAssertEqual(player.progress, 1, accuracy: 0.01)
    }

    func testStopResetsPlaybackPosition() async throws {
        let audioFile = try await MessagesAudioTestFile.make(duration: 2)
        let player = MessagesAudioPlayer(fileURL: audioFile.url, duration: nil)

        let becameAvailable = await waitUntil {
            player.isAvailable
        }

        XCTAssertTrue(becameAvailable)

        guard becameAvailable else { return }

        player.seek(to: 0.5)

        XCTAssertGreaterThan(player.currentTime, 0)

        player.stop()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.02)
        XCTAssertEqual(player.progress, 0, accuracy: 0.01)
    }

    func testTogglePlaybackStartsAndPausesAudio() async throws {
        let audioFile = try await MessagesAudioTestFile.make(duration: 2)
        let player = MessagesAudioPlayer(fileURL: audioFile.url, duration: nil)

        defer {
            player.stop()
        }

        let becameAvailable = await waitUntil {
            player.isAvailable
        }

        XCTAssertTrue(becameAvailable)

        guard becameAvailable else { return }

        player.togglePlayback()

        let startedPlaying = await waitUntil {
            player.isPlaying && player.currentTime > 0
        }

        XCTAssertTrue(startedPlaying)

        guard startedPlaying else { return }

        player.togglePlayback()

        let paused = await waitUntil {
            !player.isPlaying
        }

        XCTAssertTrue(paused)
    }

    func testStartingSecondPlayerPausesFirstPlayer() async throws {
        let firstAudioFile = try await MessagesAudioTestFile.make(duration: 2)
        let secondAudioFile = try await MessagesAudioTestFile.make(duration: 2)
        let firstPlayer = MessagesAudioPlayer(fileURL: firstAudioFile.url, duration: nil)
        let secondPlayer = MessagesAudioPlayer(fileURL: secondAudioFile.url, duration: nil)

        defer {
            firstPlayer.stop()
            secondPlayer.stop()
        }

        let playersBecameAvailable = await waitUntil {
            firstPlayer.isAvailable && secondPlayer.isAvailable
        }

        XCTAssertTrue(playersBecameAvailable)

        guard playersBecameAvailable else { return }

        firstPlayer.togglePlayback()

        let firstPlayerStarted = await waitUntil {
            firstPlayer.isPlaying && firstPlayer.currentTime > 0
        }

        XCTAssertTrue(firstPlayerStarted)

        guard firstPlayerStarted else { return }

        XCTAssertFalse(secondPlayer.isPlaying)

        secondPlayer.togglePlayback()

        let secondPlayerStarted = await waitUntil {
            !firstPlayer.isPlaying
                && secondPlayer.isPlaying
                && secondPlayer.currentTime > 0
        }

        XCTAssertTrue(secondPlayerStarted)
    }

    private func waitUntil(timeout: TimeInterval = 3, condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        return condition()
    }
}

private final class MessagesAudioTestFile: @unchecked Sendable {

    let url: URL

    private let directoryURL: URL

    static func make(duration: TimeInterval, containsSignal: Bool = false) async throws -> MessagesAudioTestFile {
        try await Task.detached(priority: .utility) {
            try MessagesAudioTestFile(duration: duration, containsSignal: containsSignal)
        }.value
    }

    private init(duration: TimeInterval, containsSignal: Bool) throws {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("recording.caf")
        let sampleRate = 8_000.0
        let frameCountValue = max(Int((duration * sampleRate).rounded()), 1)

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw MessagesAudioTestFileError.couldNotCreateFormat
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCountValue)) else {
            throw MessagesAudioTestFileError.couldNotCreateBuffer
        }

        buffer.frameLength = AVAudioFrameCount(frameCountValue)

        guard let samples = buffer.floatChannelData?[0] else {
            throw MessagesAudioTestFileError.couldNotAccessSamples
        }

        let denominator = Float(max(frameCountValue - 1, 1))

        for frame in 0..<frameCountValue {
            if containsSignal {
                samples[frame] = 0.5 * Float(frame) / denominator
            } else {
                samples[frame] = 0
            }
        }

        let audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)

        try audioFile.write(from: buffer)

        self.directoryURL = directoryURL
        self.url = fileURL
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

private enum MessagesAudioTestFileError: Error {
    case couldNotCreateFormat
    case couldNotCreateBuffer
    case couldNotAccessSamples
}
