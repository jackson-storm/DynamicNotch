import Foundation
import Dispatch

final class MediaRemoteNowPlayingService: NowPlayingMonitoring, NowPlayingDetailPollingConfigurable, @unchecked Sendable {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    private struct AdapterStreamMessage: Decodable {
        let type: String?
        let payload: AdapterPayload?
    }

    fileprivate struct AdapterPayload: Decodable {
        let processIdentifier: Int?
        let bundleIdentifier: String?
        let parentApplicationBundleIdentifier: String?
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
        let shuffleMode: Int?
        let repeatMode: Int?
        let volume: Double?
        let artworkData: String?
        let mediaType: String?
        let contentItemIdentifier: String?
    }

    private static let perlExecutableURL = URL(fileURLWithPath: "/usr/bin/perl")
    private static let microsecondsPerSecond: Double = 1_000_000

    private let callbackQueue = DispatchQueue(
        label: "com.dynamicnotch.nowplaying",
        qos: .utility
    )
    private let decoder = JSONDecoder()
    private let commandDispatcher = MediaRemoteCommandDispatcher()
    private let applicationBridge = NowPlayingApplicationBridge()

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var outputBuffer = ""
    private var lastSnapshot: NowPlayingSnapshot?
    private var favoriteRefreshTask: Task<Void, Never>?
    private var favoriteRefreshKey: String?
    private var applicationPlaybackRefreshTask: Task<Void, Never>?
    private var applicationPlaybackStates: [String: NowPlayingApplicationPlaybackState] = [:]
    private var applicationPlaybackRefreshKeys: [String: String] = [:]
    private var applicationPlaybackObservers: [NSObjectProtocol] = []
    private var applicationPlaybackPollTimer: DispatchSourceTimer?
    private var isDetailPollingEnabled = false
    private var isMonitoring = false
    private var restartWorkItem: DispatchWorkItem?

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        startApplicationPlaybackObservers()
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

        favoriteRefreshTask?.cancel()
        favoriteRefreshTask = nil
        favoriteRefreshKey = nil
        applicationPlaybackRefreshTask?.cancel()
        applicationPlaybackRefreshTask = nil
        isDetailPollingEnabled = false
        applicationPlaybackStates.removeAll()
        applicationPlaybackRefreshKeys.removeAll()
        stopApplicationPlaybackObservers()
        stopApplicationPlaybackPolling()

        callbackQueue.async { [weak self] in
            self?.lastSnapshot = nil
        }
    }

    func send(_ command: NowPlayingCommand) {
        if command.requiresApplicationBridge,
           applicationBridge.send(command, source: lastSnapshot?.playbackSource) {
            recordOptimisticApplicationPlaybackState(for: command)
            scheduleApplicationPlaybackRefresh(for: lastSnapshot, force: true, delay: 0.2)
            return
        }

        commandDispatcher.send(command)
    }

    func setDetailPollingEnabled(_ isEnabled: Bool) {
        callbackQueue.async { [weak self] in
            guard let self, self.isDetailPollingEnabled != isEnabled else { return }

            self.isDetailPollingEnabled = isEnabled

            if isEnabled {
                self.refreshFavoriteStateIfNeeded(for: self.lastSnapshot)
                self.scheduleApplicationPlaybackRefresh(for: self.lastSnapshot, force: false)
                self.updateApplicationPlaybackPolling(for: self.lastSnapshot)
            } else {
                self.favoriteRefreshTask?.cancel()
                self.favoriteRefreshTask = nil
                self.applicationPlaybackRefreshTask?.cancel()
                self.applicationPlaybackRefreshTask = nil
                self.stopApplicationPlaybackPolling()
            }
        }
    }
}

private extension NowPlayingCommand {
    var requiresApplicationBridge: Bool {
        switch self {
        case .play, .pause, .seek, .setVolume, .setFavorite:
            return true
        case .togglePlayPause, .nextTrack, .previousTrack, .setShuffle, .setRepeatMode:
            return false
        }
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
        if isDetailPollingEnabled {
            refreshFavoriteStateIfNeeded(for: snapshot)
            scheduleApplicationPlaybackRefresh(for: snapshot, force: false)
        }
        updateApplicationPlaybackPolling(for: snapshot)

        DispatchQueue.main.async { [weak self] in
            self?.onSnapshotChange?(snapshot)
        }
    }

    func startApplicationPlaybackObservers() {
        guard applicationPlaybackObservers.isEmpty else { return }

        [
            "com.apple.Music.playerInfo",
            "com.spotify.client.PlaybackStateChanged"
        ].forEach { notificationName in
            let observer = DistributedNotificationCenter.default().addObserver(
                forName: Notification.Name(notificationName),
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.callbackQueue.async { [weak self] in
                    self?.scheduleApplicationPlaybackRefresh(
                        for: self?.lastSnapshot,
                        force: true
                    )
                }
            }

            applicationPlaybackObservers.append(observer)
        }
    }

    func stopApplicationPlaybackObservers() {
        applicationPlaybackObservers.forEach {
            DistributedNotificationCenter.default().removeObserver($0)
        }

        applicationPlaybackObservers.removeAll()
    }

    func recordOptimisticApplicationPlaybackState(for command: NowPlayingCommand) {
        guard let snapshot = lastSnapshot,
              let bundleIdentifier = snapshot.playbackSource?.preferredBundleIdentifier,
              supportsApplicationPlaybackState(bundleIdentifier: bundleIdentifier),
              let isPlaying = command.optimisticPlaybackState else {
            return
        }

        let state = NowPlayingApplicationPlaybackState(
            bundleIdentifier: bundleIdentifier,
            isPlaying: isPlaying,
            title: snapshot.title,
            artist: snapshot.artist,
            album: snapshot.album,
            elapsedTime: snapshot.elapsedTime(at: .now),
            duration: snapshot.duration,
            isShuffled: snapshot.isShuffled,
            repeatMode: snapshot.repeatMode,
            volume: snapshot.volume,
            refreshedAt: .now
        )

        applicationPlaybackStates[bundleIdentifier] = state
        applicationPlaybackRefreshKeys[bundleIdentifier] = snapshot.applicationPlaybackRefreshKey

        let updatedSnapshot = snapshot.applying(applicationPlaybackState: state)
        lastSnapshot = updatedSnapshot

        DispatchQueue.main.async { [weak self] in
            self?.onSnapshotChange?(updatedSnapshot)
        }
    }

    func scheduleApplicationPlaybackRefresh(
        for snapshot: NowPlayingSnapshot?,
        force: Bool,
        delay: TimeInterval = 0
    ) {
        guard let snapshot,
              let bundleIdentifier = snapshot.playbackSource?.preferredBundleIdentifier,
              supportsApplicationPlaybackState(bundleIdentifier: bundleIdentifier) else {
            return
        }

        let refreshKey = snapshot.applicationPlaybackRefreshKey

        if !force,
           applicationPlaybackStates[bundleIdentifier] != nil,
           applicationPlaybackRefreshKeys[bundleIdentifier] == refreshKey {
            return
        }

        applicationPlaybackRefreshTask?.cancel()
        applicationPlaybackRefreshKeys[bundleIdentifier] = refreshKey

        applicationPlaybackRefreshTask = Task { [weak self, applicationBridge] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            guard !Task.isCancelled,
                  let applicationPlaybackState = await applicationBridge.playbackState(
                      for: snapshot.playbackSource
                  ) else {
                return
            }

            self?.callbackQueue.async { [weak self] in
                guard let self else { return }

                self.applicationPlaybackStates[bundleIdentifier] = applicationPlaybackState

                guard let currentSnapshot = self.lastSnapshot,
                      currentSnapshot.playbackSource?.preferredBundleIdentifier == bundleIdentifier,
                      applicationPlaybackState.matches(currentSnapshot) else {
                    return
                }

                self.publish(
                    snapshot: currentSnapshot.applying(
                        applicationPlaybackState: applicationPlaybackState
                    )
                )
            }
        }
    }

    func updateApplicationPlaybackPolling(for snapshot: NowPlayingSnapshot?) {
        guard isDetailPollingEnabled,
              let bundleIdentifier = snapshot?.playbackSource?.preferredBundleIdentifier,
              supportsApplicationPlaybackState(bundleIdentifier: bundleIdentifier) else {
            stopApplicationPlaybackPolling()
            return
        }

        guard applicationPlaybackPollTimer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: callbackQueue)
        timer.schedule(deadline: .now() + 1, repeating: 1.25)
        timer.setEventHandler { [weak self] in
            self?.scheduleApplicationPlaybackRefresh(
                for: self?.lastSnapshot,
                force: true
            )
        }
        timer.resume()
        applicationPlaybackPollTimer = timer
    }

    func stopApplicationPlaybackPolling() {
        applicationPlaybackPollTimer?.cancel()
        applicationPlaybackPollTimer = nil
    }

    func supportsApplicationPlaybackState(bundleIdentifier: String?) -> Bool {
        switch bundleIdentifier {
        case "com.apple.Music", "com.spotify.client", "com.github.th-ch.youtube-music":
            return true
        default:
            return false
        }
    }

    func refreshFavoriteStateIfNeeded(for snapshot: NowPlayingSnapshot?) {
        guard let snapshot, snapshot.supportsFavorite else {
            favoriteRefreshTask?.cancel()
            favoriteRefreshTask = nil
            favoriteRefreshKey = nil
            return
        }

        let refreshKey = snapshot.favoriteRefreshKey
        guard favoriteRefreshKey != refreshKey || snapshot.isFavorite == nil else { return }

        favoriteRefreshTask?.cancel()
        favoriteRefreshKey = refreshKey

        favoriteRefreshTask = Task { [weak self, applicationBridge] in
            guard let isFavorite = await applicationBridge.favoriteState(for: snapshot.playbackSource) else {
                return
            }

            self?.callbackQueue.async { [weak self] in
                guard let self,
                      let currentSnapshot = self.lastSnapshot,
                      currentSnapshot.favoriteRefreshKey == refreshKey else {
                    return
                }

                self.publish(snapshot: currentSnapshot.settingFavorite(isFavorite))
            }
        }
    }

    private func makeSnapshot(from payload: AdapterPayload?) -> NowPlayingSnapshot? {
        guard let payload, payload.isActive else { return nil }

        var snapshot = NowPlayingSnapshot(
            title: payload.title?.trimmed ?? "",
            artist: payload.artist?.trimmed ?? "",
            album: payload.album?.trimmed ?? "",
            duration: payload.durationSeconds,
            elapsedTime: payload.elapsedSeconds,
            playbackRate: payload.resolvedPlaybackRate,
            artworkData: decodeArtworkData(payload.artworkData),
            playbackSource: payload.playbackSource,
            mediaType: payload.mediaType,
            contentItemIdentifier: payload.contentItemIdentifier,
            isShuffled: payload.resolvedShuffleState(previousSnapshot: lastSnapshot),
            repeatMode: payload.resolvedRepeatMode(previousSnapshot: lastSnapshot),
            volume: payload.resolvedVolume(previousSnapshot: lastSnapshot),
            isFavorite: payload.resolvedFavoriteState(previousSnapshot: lastSnapshot),
            supportsFavorite: payload.playbackSource?.supportsFavoriteCommand ?? false,
            supportsVolumeControl: payload.playbackSource?.supportsVolumeCommand ?? false,
            refreshedAt: .now
        )

        if let applicationPlaybackState = snapshot.resolvedApplicationPlaybackState(
            from: applicationPlaybackStates
        ) {
            snapshot = snapshot.applying(applicationPlaybackState: applicationPlaybackState)
        }

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

private extension NowPlayingCommand {
    var optimisticPlaybackState: Bool? {
        switch self {
        case .play:
            return true
        case .pause:
            return false
        default:
            return nil
        }
    }
}

private extension MediaRemoteNowPlayingService.AdapterPayload {
    var playbackSource: NowPlayingPlaybackSource? {
        let source = NowPlayingPlaybackSource(
            bundleIdentifier: bundleIdentifier,
            parentBundleIdentifier: parentApplicationBundleIdentifier,
            processIdentifier: processIdentifier
        )

        return source.hasOpenableTarget ? source : nil
    }

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

    func resolvedShuffleState(previousSnapshot: NowPlayingSnapshot?) -> Bool {
        guard let shuffleMode else {
            return previousSnapshot?.isShuffled ?? false
        }

        return shuffleMode != 1
    }

    func resolvedRepeatMode(previousSnapshot: NowPlayingSnapshot?) -> NowPlayingRepeatMode {
        guard let repeatMode else {
            return previousSnapshot?.repeatMode ?? .off
        }

        return NowPlayingRepeatMode(mediaRemoteValue: repeatMode)
    }

    func resolvedVolume(previousSnapshot: NowPlayingSnapshot?) -> Double? {
        guard let volume else {
            return previousSnapshot?.volume
        }

        if volume > 1 {
            return min(max(volume / 100, 0), 1)
        }

        return min(max(volume, 0), 1)
    }

    func resolvedFavoriteState(previousSnapshot: NowPlayingSnapshot?) -> Bool? {
        guard let previousSnapshot,
              previousSnapshot.favoriteRefreshKey == playbackFavoriteRefreshKey else {
            return nil
        }

        return previousSnapshot.isFavorite
    }

    var playbackFavoriteRefreshKey: String {
        [
            playbackSource?.preferredBundleIdentifier,
            title?.trimmed,
            artist?.trimmed,
            album?.trimmed
        ]
            .compactMap { $0 }
            .joined(separator: "|")
    }

    private func seconds(fromMicroseconds microseconds: Int64?) -> TimeInterval? {
        guard let microseconds else { return nil }
        return TimeInterval(microseconds) / MediaRemoteNowPlayingService.microsecondsPerSecond
    }
}

private extension NowPlayingSnapshot {
    var applicationPlaybackRefreshKey: String {
        [
            playbackSource?.preferredBundleIdentifier,
            title.trimmed,
            artist.trimmed,
            album.trimmed
        ]
            .compactMap { $0 }
            .joined(separator: "|")
    }

    var favoriteRefreshKey: String {
        [
            playbackSource?.preferredBundleIdentifier,
            title.trimmed,
            artist.trimmed,
            album.trimmed
        ]
            .compactMap { $0 }
            .joined(separator: "|")
    }

    func resolvedApplicationPlaybackState(
        from states: [String: NowPlayingApplicationPlaybackState]
    ) -> NowPlayingApplicationPlaybackState? {
        guard let bundleIdentifier = playbackSource?.preferredBundleIdentifier,
              let state = states[bundleIdentifier],
              state.matches(self) else {
            return nil
        }

        return state
    }

    func applying(applicationPlaybackState state: NowPlayingApplicationPlaybackState) -> Self {
        Self(
            title: state.title?.trimmed.nonEmpty ?? title,
            artist: state.artist?.trimmed.nonEmpty ?? artist,
            album: state.album?.trimmed.nonEmpty ?? album,
            duration: state.duration ?? duration,
            elapsedTime: state.elapsedTime ?? elapsedTime(at: state.refreshedAt),
            playbackRate: state.isPlaying ? max(playbackRate, 1) : 0,
            artworkData: artworkData,
            playbackSource: playbackSource,
            mediaType: mediaType,
            contentItemIdentifier: contentItemIdentifier,
            isShuffled: state.isShuffled ?? isShuffled,
            repeatMode: state.repeatMode ?? repeatMode,
            volume: state.volume ?? volume,
            isFavorite: isFavorite,
            supportsFavorite: supportsFavorite,
            supportsVolumeControl: supportsVolumeControl,
            refreshedAt: state.refreshedAt
        )
    }

    func settingFavorite(_ isFavorite: Bool) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime,
            playbackRate: playbackRate,
            artworkData: artworkData,
            playbackSource: playbackSource,
            mediaType: mediaType,
            contentItemIdentifier: contentItemIdentifier,
            isShuffled: isShuffled,
            repeatMode: repeatMode,
            volume: volume,
            isFavorite: isFavorite,
            supportsFavorite: supportsFavorite,
            supportsVolumeControl: supportsVolumeControl,
            refreshedAt: refreshedAt
        )
    }
}

private extension NowPlayingApplicationPlaybackState {
    func matches(_ snapshot: NowPlayingSnapshot) -> Bool {
        metadataValueMatches(title, snapshot.title) &&
        metadataValueMatches(artist, snapshot.artist) &&
        metadataValueMatches(album, snapshot.album)
    }

    private func metadataValueMatches(_ lhs: String?, _ rhs: String) -> Bool {
        guard let lhs = lhs?.trimmed, !lhs.isEmpty else { return true }
        let rhs = rhs.trimmed
        guard !rhs.isEmpty else { return true }
        return lhs == rhs
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
