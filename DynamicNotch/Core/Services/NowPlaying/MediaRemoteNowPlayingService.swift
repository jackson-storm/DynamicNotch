import Foundation
import Dispatch

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
    private let commandDispatcher = MediaRemoteCommandDispatcher()
    private let elapsedTimeDispatcher = MediaRemoteElapsedTimeDispatcher()

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
        switch command {
        case .seek(let position):
            elapsedTimeDispatcher.seek(to: position)
        default:
            commandDispatcher.send(command)
        }
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
