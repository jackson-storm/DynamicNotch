import Foundation
import Dispatch
import Darwin
import AppKit

enum NowPlayingCommand: Equatable {
    case togglePlayPause
    case nextTrack
    case previousTrack
}

struct NowPlayingSnapshot: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let playbackRate: Double
    let artworkData: Data?
    let refreshedAt: Date

    var isPlaying: Bool {
        playbackRate > 0.001
    }

    var hasVisibleMetadata: Bool {
        !title.trimmed.isEmpty ||
        !artist.trimmed.isEmpty ||
        !album.trimmed.isEmpty ||
        artworkData?.isEmpty == false ||
        duration > 0
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        let baseElapsed = max(0, elapsedTime)

        guard isPlaying else {
            if duration > 0 {
                return min(baseElapsed, duration)
            }
            return baseElapsed
        }

        let advancedElapsed = baseElapsed + (date.timeIntervalSince(refreshedAt) * playbackRate)

        if duration > 0 {
            return min(max(0, advancedElapsed), duration)
        }

        return max(0, advancedElapsed)
    }

    static func == (lhs: NowPlayingSnapshot, rhs: NowPlayingSnapshot) -> Bool {
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
        lhs.duration == rhs.duration &&
        lhs.elapsedTime == rhs.elapsedTime &&
        lhs.playbackRate == rhs.playbackRate &&
        lhs.artworkData == rhs.artworkData
    }
}

protocol NowPlayingMonitoring: AnyObject {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
    func send(_ command: NowPlayingCommand)
}

final class InactiveNowPlayingService: NowPlayingMonitoring {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    func startMonitoring() {
        onSnapshotChange?(nil)
    }

    func stopMonitoring() {}

    func send(_ command: NowPlayingCommand) {}
}

final class MediaRemoteNowPlayingService: NowPlayingMonitoring {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    private struct HelperSnapshot: Decodable {
        let active: Bool
        let title: String?
        let artist: String?
        let album: String?
        let duration: Double?
        let elapsedTime: Double?
        let playbackRate: Double?
        let artworkData: String?
    }

    private static let sourceHelperScriptURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("mediaremote-helper.swiftscript")
    private static let swiftExecutableURL = URL(fileURLWithPath: "/usr/bin/swift")

    private let callbackQueue = DispatchQueue(
        label: "com.dynamicnotch.nowplaying",
        qos: .userInitiated
    )
    private let decoder = JSONDecoder()
    private let mediaKeyDispatcher = MediaKeyCommandDispatcher()

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputBuffer = ""
    private var lastSnapshot: NowPlayingSnapshot?
    private var isMonitoring = false
    private var restartWorkItem: DispatchWorkItem?

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        launchHelperProcess()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        restartWorkItem?.cancel()
        restartWorkItem = nil

        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil

        process?.terminationHandler = nil

        if let process, process.isRunning {
            process.terminate()
        }

        process = nil
        outputPipe = nil
        errorPipe = nil
        outputBuffer = ""

        callbackQueue.async { [weak self] in
            self?.lastSnapshot = nil
        }
    }

    func send(_ command: NowPlayingCommand) {
        mediaKeyDispatcher.send(command)
    }
}

private extension MediaRemoteNowPlayingService {
    func launchHelperProcess() {
        guard isMonitoring else { return }

        let scriptURL =
            Bundle.main.url(forResource: "mediaremote-helper", withExtension: "swiftscript") ??
            Self.sourceHelperScriptURL

        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            publish(snapshot: nil)
            return
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = Self.swiftExecutableURL
        process.arguments = [scriptURL.path]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.terminationHandler = { [weak self] terminatedProcess in
            self?.callbackQueue.async { [weak self] in
                self?.handleTermination(of: terminatedProcess)
            }
        }

        do {
            try process.run()
        } catch {
            scheduleRestart()
            return
        }

        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
        self.outputBuffer = ""

        startReadingOutput(from: outputPipe)
        startReadingErrors(from: errorPipe)
    }

    func startReadingOutput(from pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData

            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }

            self?.callbackQueue.async { [weak self] in
                self?.consumeOutputData(data)
            }
        }
    }

    func startReadingErrors(from pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData

            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }

            guard
                let message = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !message.isEmpty
            else {
                return
            }

            fputs("NowPlaying helper: \(message)\n", stderr)
        }
    }

    func consumeOutputData(_ data: Data) {
        guard let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty else {
            return
        }

        outputBuffer.append(chunk)

        while let lineBreak = outputBuffer.firstIndex(of: "\n") {
            let line = String(outputBuffer[..<lineBreak])
            outputBuffer.removeSubrange(...lineBreak)

            guard !line.isEmpty else { continue }
            processHelperLine(line)
        }
    }

    func processHelperLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        do {
            let helperSnapshot = try decoder.decode(HelperSnapshot.self, from: data)
            publish(snapshot: makeSnapshot(from: helperSnapshot))
        } catch {
            return
        }
    }

    func handleTermination(of terminatedProcess: Process) {
        guard process === terminatedProcess else { return }

        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process = nil
        outputPipe = nil
        errorPipe = nil
        outputBuffer = ""

        guard isMonitoring else { return }
        scheduleRestart()
    }

    func scheduleRestart() {
        restartWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.launchHelperProcess()
        }

        restartWorkItem = workItem
        callbackQueue.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    func publish(snapshot: NowPlayingSnapshot?) {
        guard snapshot != lastSnapshot else { return }

        lastSnapshot = snapshot

        DispatchQueue.main.async { [weak self] in
            self?.onSnapshotChange?(snapshot)
        }
    }

    private func makeSnapshot(from helperSnapshot: HelperSnapshot) -> NowPlayingSnapshot? {
        guard helperSnapshot.active else {
            return nil
        }

        let snapshot = NowPlayingSnapshot(
            title: helperSnapshot.title ?? "",
            artist: helperSnapshot.artist ?? "",
            album: helperSnapshot.album ?? "",
            duration: helperSnapshot.duration ?? 0,
            elapsedTime: helperSnapshot.elapsedTime ?? 0,
            playbackRate: helperSnapshot.playbackRate ?? 0,
            artworkData: decodeArtworkData(helperSnapshot.artworkData),
            refreshedAt: .now
        )

        return snapshot.hasVisibleMetadata ? snapshot : nil
    }

    private func decodeArtworkData(_ base64String: String?) -> Data? {
        guard let base64String else { return nil }

        return Data(
            base64Encoded: base64String.trimmingCharacters(in: .whitespacesAndNewlines),
            options: .ignoreUnknownCharacters
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private final class MediaKeyCommandDispatcher {
    private enum MediaKeyCode: Int32 {
        case playPause = 16
        case nextTrack = 17
        case previousTrack = 18
    }

    private let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    private var didPromptForEventAccess = false
    private var didOpenPrivacySettings = false

    func send(_ command: NowPlayingCommand) {
        guard ensureEventSynthesizingAccess() else { return }

        let keyCode: MediaKeyCode

        switch command {
        case .togglePlayPause:
            keyCode = .playPause
        case .nextTrack:
            keyCode = .nextTrack
        case .previousTrack:
            keyCode = .previousTrack
        }

        postMediaKeyEvent(keyCode, isKeyDown: true)
        postMediaKeyEvent(keyCode, isKeyDown: false)
    }

    private func ensureEventSynthesizingAccess() -> Bool {
        if CGPreflightPostEventAccess() {
            return true
        }

        if !didPromptForEventAccess {
            didPromptForEventAccess = true

            if CGRequestPostEventAccess() {
                return true
            }
        }

        guard !CGPreflightPostEventAccess() else {
            return true
        }

        if !didOpenPrivacySettings, let privacySettingsURL {
            didOpenPrivacySettings = true
            NSWorkspace.shared.open(privacySettingsURL)
        }

        return false
    }

    private func postMediaKeyEvent(_ keyCode: MediaKeyCode, isKeyDown: Bool) {
        let flags = NSEvent.ModifierFlags(rawValue: isKeyDown ? 0xA00 : 0xB00)
        let keyState = isKeyDown ? 0xA : 0xB
        let data1 = Int((keyCode.rawValue << 16) | Int32(keyState << 8))

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: flags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        ) else {
            return
        }

        event.cgEvent?.post(tap: .cghidEventTap)
    }
}
