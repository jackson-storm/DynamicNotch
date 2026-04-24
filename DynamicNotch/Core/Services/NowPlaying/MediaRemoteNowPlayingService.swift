import Foundation
import Dispatch

final class MediaRemoteNowPlayingService: NowPlayingMonitoring {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    private struct AdapterStreamMessage: Decodable {
        let type: String?
        let payload: AdapterPayload?
    }

    fileprivate struct AdapterPayload: Decodable {
        let playing: Bool?
        let title: String?
        let artist: String?
        let album: String?
        let duration: Double?
        let durationMicros: Int64?
        let elapsedTime: Double?
        let elapsedTimeMicros: Int64?
        let elapsedTimeNow: Double?
        let elapsedTimeNowMicros: Int64?
        let playbackRate: Double?
        let artworkData: String?
    }

    private static let perlExecutableURL = URL(fileURLWithPath: "/usr/bin/perl")
    private static let microsecondsPerSecond: Double = 1_000_000

    private let callbackQueue = DispatchQueue(
        label: "com.dynamicnotch.nowplaying",
        qos: .utility
    )
    private let decoder = JSONDecoder()
    private let commandDispatcher = MediaRemoteCommandDispatcher()

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
        commandDispatcher.send(command)
    }
}

private extension MediaRemoteNowPlayingService {
    func launchHelperProcess() {
        guard isMonitoring else { return }

        guard let resources = MediaRemoteAdapterResources.resolve() else {
            publish(snapshot: nil)
            return
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = Self.perlExecutableURL
        process.arguments = resources.invocationArguments(
            for: [
                "stream",
                "--no-diff",
                "--debounce=150"
            ]
        )
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

            fputs("MediaRemote adapter: \(message)\n", stderr)
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
            processAdapterLine(line)
        }
    }

    func processAdapterLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        do {
            let message = try decoder.decode(AdapterStreamMessage.self, from: data)
            guard message.type == nil || message.type == "data" else { return }
            publish(snapshot: makeSnapshot(from: message.payload))
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

        if terminatedProcess.terminationReason == .exit,
           terminatedProcess.terminationStatus != 0 {
            publish(snapshot: nil)
            return
        }

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

    private func makeSnapshot(from payload: AdapterPayload?) -> NowPlayingSnapshot? {
        guard let payload, payload.isActive else { return nil }

        let snapshot = NowPlayingSnapshot(
            title: payload.title?.trimmed ?? "",
            artist: payload.artist?.trimmed ?? "",
            album: payload.album?.trimmed ?? "",
            duration: payload.durationSeconds,
            elapsedTime: payload.elapsedSeconds,
            playbackRate: payload.resolvedPlaybackRate,
            artworkData: decodeArtworkData(payload.artworkData),
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

private extension MediaRemoteNowPlayingService.AdapterPayload {
    var isActive: Bool {
        !(title?.trimmed.isEmpty ?? true) ||
        !(artist?.trimmed.isEmpty ?? true) ||
        !(album?.trimmed.isEmpty ?? true) ||
        artworkData != nil ||
        durationSeconds > 0 ||
        elapsedSeconds > 0
    }

    var durationSeconds: TimeInterval {
        duration ?? seconds(fromMicroseconds: durationMicros) ?? 0
    }

    var elapsedSeconds: TimeInterval {
        elapsedTime ??
        seconds(fromMicroseconds: elapsedTimeMicros) ??
        elapsedTimeNow ??
        seconds(fromMicroseconds: elapsedTimeNowMicros) ??
        0
    }

    var resolvedPlaybackRate: Double {
        playbackRate ?? (playing == true ? 1 : 0)
    }

    private func seconds(fromMicroseconds microseconds: Int64?) -> TimeInterval? {
        guard let microseconds else { return nil }
        return TimeInterval(microseconds) / MediaRemoteNowPlayingService.microsecondsPerSecond
    }
}
