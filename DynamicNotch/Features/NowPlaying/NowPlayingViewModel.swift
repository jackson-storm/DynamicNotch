internal import AppKit
import Combine
import SwiftUI

@MainActor
protocol PlaybackSourceOpening {
    func openPlaybackSource(_ source: NowPlayingPlaybackSource)
}

@MainActor
final class WorkspacePlaybackSourceOpener: PlaybackSourceOpening {
    func openPlaybackSource(_ source: NowPlayingPlaybackSource) {
        if let bundleIdentifier = source.preferredBundleIdentifier {
            if openApplication(bundleIdentifier: bundleIdentifier) {
                return
            }
        }

        if let processIdentifier = source.validProcessIdentifier,
           let application = NSRunningApplication(processIdentifier: pid_t(processIdentifier)) {
            showRunningApplication(application)
        }
    }
}

@MainActor
final class NowPlayingViewModel: ObservableObject {
    private static let favoriteTrackKeysStorageKey = "settings.nowPlaying.favoriteTrackKeys"

    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var artworkPalette = NowPlayingArtworkPalette.fallback
    @Published private(set) var artworkFlipAngle: Double = 0
    @Published private(set) var audioOutputRoutes: [AudioOutputRoute] = []
    @Published private(set) var currentAudioOutputRoute: AudioOutputRoute?
    @Published private(set) var isCurrentTrackFavorite = false
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private let audioOutputRouting: any AudioOutputRouting
    private let favoritesStore: UserDefaults
    private let detailPollingService: (any NowPlayingDetailPollingConfigurable)?
    private let playbackSourceOpener: any PlaybackSourceOpening
    private let artworkFlipAnimationDuration: TimeInterval = 0.45
    private let artworkSwapDelay: TimeInterval = 0.4
    private let transientSessionGracePeriod: TimeInterval = 0.55
    private var hasStartedMonitoring = false
    private var ignoresServiceSnapshots = false
    private var artworkFlipCooldownActive = false
    private var artworkPresentationWorkItem: DispatchWorkItem?
    private var pendingSessionEndWorkItem: DispatchWorkItem?
    private var artworkFlipTrackKey: String?
    private var artworkFlipStartedAt: Date?
    private var activeDetailedPresentationSources = Set<String>()
    #if DEBUG
    private var isShowingDebugPreviewSnapshot = false
    #endif

    var hasActiveSession: Bool {
        snapshot != nil
    }

    convenience init() {
        self.init(
            service: MediaRemoteNowPlayingService(),
            audioOutputRouting: SystemAudioOutputRoutingService(),
            favoritesStore: .standard,
            playbackSourceOpener: WorkspacePlaybackSourceOpener()
        )
    }

    init(
        service: any NowPlayingMonitoring,
        audioOutputRouting: (any AudioOutputRouting)? = nil,
        favoritesStore: UserDefaults = .standard,
        playbackSourceOpener: (any PlaybackSourceOpening)? = nil
    ) {
        self.service = service
        self.audioOutputRouting = audioOutputRouting ?? InactiveAudioOutputRoutingService()
        self.favoritesStore = favoritesStore
        self.detailPollingService = service as? any NowPlayingDetailPollingConfigurable
        self.playbackSourceOpener = playbackSourceOpener ?? WorkspacePlaybackSourceOpener()
        self.service.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.handleServiceSnapshot(snapshot)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.handleServiceSnapshot(snapshot)
                }
            }
        }
        refreshAudioOutputRoutes()
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        ignoresServiceSnapshots = false
        service.startMonitoring()
        updateDetailPollingState()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false
        ignoresServiceSnapshots = true
        service.stopMonitoring()
        activeDetailedPresentationSources.removeAll()
        updateDetailPollingState()
        cancelPendingSessionEnd()
        cancelPendingArtworkPresentation()
        apply(snapshot: nil)
    }

    func togglePlayPause() {
        guard let snapshot else {
            service.send(.togglePlayPause)
            return
        }

        let command: NowPlayingCommand = snapshot.isPlaying ? .pause : .play
        apply(snapshot: snapshot.togglingPlaybackState())
        service.send(command)
    }

    func play() {
        if let snapshot, !snapshot.isPlaying {
            apply(snapshot: snapshot.settingPlaybackRate(1))
        }

        service.send(.play)
    }

    func pause() {
        if let snapshot, snapshot.isPlaying {
            apply(snapshot: snapshot.settingPlaybackRate(0))
        }

        service.send(.pause)
    }

    func nextTrack() {
        service.send(.nextTrack)
    }

    func previousTrack() {
        service.send(.previousTrack)
    }

    func seek(to elapsedTime: TimeInterval) {
        guard let snapshot, snapshot.duration > 0 else { return }

        let clampedElapsedTime = min(max(elapsedTime, 0), snapshot.duration)
        apply(snapshot: snapshot.settingElapsedTime(clampedElapsedTime))
        service.send(.seek(clampedElapsedTime))
    }

    func skip(seconds: TimeInterval) {
        guard let snapshot else { return }
        seek(to: snapshot.elapsedTime(at: .now) + seconds)
    }

    func toggleShuffle() {
        guard let snapshot else { return }

        let isShuffled = !snapshot.isShuffled
        apply(snapshot: snapshot.settingShuffle(isShuffled), emitEvent: false)
        service.send(.setShuffle(isShuffled))
    }

    func toggleRepeat() {
        guard let snapshot else { return }

        let repeatMode = snapshot.repeatMode.next
        apply(snapshot: snapshot.settingRepeatMode(repeatMode), emitEvent: false)
        service.send(.setRepeatMode(repeatMode))
    }

    func setVolume(_ volume: Double) {
        guard let snapshot, snapshot.supportsVolumeControl else { return }

        let clampedVolume = min(max(volume, 0), 1)
        apply(snapshot: snapshot.settingVolume(clampedVolume), emitEvent: false)
        service.send(.setVolume(clampedVolume))
    }

    func refreshAudioOutputRoutes() {
        let routes = audioOutputRouting.availableRoutes()
        audioOutputRoutes = routes
        currentAudioOutputRoute = routes.first(where: \.isCurrent)
    }

    func switchAudioOutput(to route: AudioOutputRoute) {
        guard audioOutputRouting.setCurrentRoute(route.id) else {
            refreshAudioOutputRoutes()
            return
        }

        refreshAudioOutputRoutes()
    }

    var canToggleFavorite: Bool {
        snapshot?.supportsFavorite == true || snapshot?.favoriteTrackKey != nil
    }

    var canOpenPlaybackSource: Bool {
        snapshot?.playbackSource?.hasOpenableTarget == true
    }

    func openPlaybackSource() {
        guard let source = snapshot?.playbackSource else { return }
        playbackSourceOpener.openPlaybackSource(source)
    }

    func toggleFavorite() {
        guard let snapshot else { return }

        if snapshot.supportsFavorite {
            let isFavorite = !(snapshot.isFavorite ?? isCurrentTrackFavorite)
            isCurrentTrackFavorite = isFavorite
            apply(snapshot: snapshot.settingFavorite(isFavorite), emitEvent: false)
            service.send(.setFavorite(isFavorite))
            return
        }

        guard let favoriteTrackKey = snapshot.favoriteTrackKey else { return }

        var favoriteTrackKeys = storedFavoriteTrackKeys

        if favoriteTrackKeys.contains(favoriteTrackKey) {
            favoriteTrackKeys.remove(favoriteTrackKey)
        } else {
            favoriteTrackKeys.insert(favoriteTrackKey)
        }

        favoritesStore.set(Array(favoriteTrackKeys).sorted(), forKey: Self.favoriteTrackKeysStorageKey)
        isCurrentTrackFavorite = favoriteTrackKeys.contains(favoriteTrackKey)
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
    }

    func setDetailedPresentationActive(_ isActive: Bool, source: String) {
        if isActive {
            activeDetailedPresentationSources.insert(source)
        } else {
            activeDetailedPresentationSources.remove(source)
        }

        updateDetailPollingState()
    }

    func clearPresentationActivityState() {
        activeDetailedPresentationSources.removeAll()
        updateDetailPollingState()
    }

    #if DEBUG
    func showDebugPreviewSnapshotIfNeeded() {
        guard snapshot == nil else { return }
        isShowingDebugPreviewSnapshot = true
        apply(snapshot: Self.makeDebugPreviewSnapshot(), emitEvent: false)
    }

    func hideDebugPreviewSnapshotIfNeeded() {
        guard isShowingDebugPreviewSnapshot else { return }
        isShowingDebugPreviewSnapshot = false
        apply(snapshot: nil, emitEvent: false)
    }

    private static func makeDebugPreviewSnapshot() -> NowPlayingSnapshot {
        NowPlayingSnapshot(
            title: "Midnight Echoes",
            artist: "Debug Ensemble",
            album: "Preview Mode",
            duration: 214,
            elapsedTime: 81,
            playbackRate: 1,
            artworkData: makeDebugArtworkData(),
            refreshedAt: .now
        )
    }

    private static func makeDebugArtworkData() -> Data? {
        let size = NSSize(width: 48, height: 48)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let rep else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        let bounds = NSRect(origin: .zero, size: size)
        NSColor(calibratedRed: 0.96, green: 0.48, blue: 0.2, alpha: 1).setFill()
        NSBezierPath(rect: bounds).fill()

        NSColor(calibratedRed: 1, green: 0.79, blue: 0.29, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size.width * 0.42, height: size.height)).fill()

        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
    #endif
}

private extension NowPlayingViewModel {
    func handleServiceSnapshot(_ snapshot: NowPlayingSnapshot?) {
        guard !ignoresServiceSnapshots else { return }

        if let snapshot {
            cancelPendingSessionEnd()
            apply(snapshot: snapshot)
        } else {
            scheduleSessionEnd()
        }
    }

    var storedFavoriteTrackKeys: Set<String> {
        Set(favoritesStore.stringArray(forKey: Self.favoriteTrackKeysStorageKey) ?? [])
    }

    func apply(snapshot newSnapshot: NowPlayingSnapshot?, emitEvent: Bool = true) {
        let wasActive = snapshot != nil
        let wasPlaying = snapshot?.isPlaying
        let previousTrackKey = snapshot?.favoriteTrackKey
        let newTrackKey = newSnapshot?.favoriteTrackKey
        let previousArtworkData = snapshot?.artworkData
        let didTrackChange = previousTrackKey != nil &&
            newTrackKey != nil &&
            previousTrackKey != newTrackKey

        if previousTrackKey != newTrackKey {
            cancelPendingArtworkPresentation()
        }

        if didTrackChange {
            triggerArtworkFlip(for: newTrackKey)
        }

        snapshot = newSnapshot
        if let remoteFavorite = newSnapshot?.isFavorite {
            isCurrentTrackFavorite = remoteFavorite
        } else {
            isCurrentTrackFavorite = newSnapshot?.favoriteTrackKey.map(storedFavoriteTrackKeys.contains) ?? false
        }

        switch newSnapshot?.artworkData {
        case let artworkData?:
            guard previousArtworkData != artworkData || artworkImage == nil else {
                break
            }

            if shouldDelayArtworkPresentation(for: newTrackKey) {
                scheduleArtworkPresentation(artworkData, for: newTrackKey)
            } else {
                applyArtworkPresentation(artworkData)
            }
        case nil:
            if newSnapshot == nil || previousArtworkData == nil {
                cancelPendingArtworkPresentation()
                artworkImage = nil
                artworkPalette = .fallback
            }
        }

        let isActive = newSnapshot != nil
        let isPlaying = newSnapshot?.isPlaying

        if emitEvent {
            if !wasActive && isActive {
                event = .started
            } else if wasActive && !isActive {
                event = .stopped
            } else if let wasPlaying, let isPlaying, wasPlaying != isPlaying {
                event = .playbackStateChanged(isPlaying: isPlaying)
            }
        }
    }

    func updateDetailPollingState() {
        detailPollingService?.setDetailPollingEnabled(
            hasStartedMonitoring && !activeDetailedPresentationSources.isEmpty
        )
    }

    func scheduleSessionEnd() {
        guard snapshot != nil else { return }
        guard pendingSessionEndWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingSessionEndWorkItem = nil
            self.cancelPendingArtworkPresentation()
            self.apply(snapshot: nil)
        }

        pendingSessionEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + transientSessionGracePeriod, execute: workItem)
    }

    func cancelPendingSessionEnd() {
        pendingSessionEndWorkItem?.cancel()
        pendingSessionEndWorkItem = nil
    }

    func triggerArtworkFlip(for trackKey: String?) {
        guard !artworkFlipCooldownActive else { return }

        artworkFlipCooldownActive = true
        artworkFlipTrackKey = trackKey
        artworkFlipStartedAt = .now

        withAnimation(.easeInOut(duration: artworkFlipAnimationDuration)) {
            artworkFlipAngle += 180
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + artworkFlipAnimationDuration + 0.15) { [weak self] in
            guard let self else { return }

            if self.artworkFlipTrackKey == trackKey {
                self.artworkFlipTrackKey = nil
                self.artworkFlipStartedAt = nil
            }

            self.artworkFlipCooldownActive = false
        }
    }

    func shouldDelayArtworkPresentation(for trackKey: String?) -> Bool {
        guard let trackKey else { return false }
        return artworkFlipTrackKey == trackKey && artworkFlipStartedAt != nil
    }

    func scheduleArtworkPresentation(_ artworkData: Data, for trackKey: String?) {
        cancelPendingArtworkPresentation()

        let elapsed = artworkFlipStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let delay = max(0, artworkSwapDelay - elapsed)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.snapshot?.favoriteTrackKey == trackKey else { return }
            self.applyArtworkPresentation(artworkData)
        }

        artworkPresentationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func cancelPendingArtworkPresentation() {
        artworkPresentationWorkItem?.cancel()
        artworkPresentationWorkItem = nil
    }

    func applyArtworkPresentation(_ artworkData: Data) {
        cancelPendingArtworkPresentation()
        artworkImage = NSImage(data: artworkData)
        artworkPalette = NowPlayingArtworkPaletteExtractor.extract(from: artworkData)
    }
}

private extension NowPlayingSnapshot {
    var favoriteTrackKey: String? {
        let components = [title.trimmed, artist.trimmed, album.trimmed]
        let joined = components.joined(separator: "|")
        return joined.replacingOccurrences(of: "|", with: "").isEmpty ? nil : joined
    }

    func togglingPlaybackState() -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
            playbackRate: isPlaying ? 0 : 1,
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
            refreshedAt: .now
        )
    }

    func settingPlaybackRate(_ newPlaybackRate: Double) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
            playbackRate: newPlaybackRate,
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
            refreshedAt: .now
        )
    }

    func settingElapsedTime(_ newElapsedTime: TimeInterval) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: min(max(newElapsedTime, 0), duration > 0 ? duration : newElapsedTime),
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
            refreshedAt: .now
        )
    }

    func settingShuffle(_ isShuffled: Bool) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
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
            refreshedAt: .now
        )
    }

    func settingRepeatMode(_ repeatMode: NowPlayingRepeatMode) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
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
            refreshedAt: .now
        )
    }

    func settingVolume(_ volume: Double) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
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
            refreshedAt: .now
        )
    }

    func settingFavorite(_ isFavorite: Bool) -> Self {
        Self(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsedTime: elapsedTime(at: .now),
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
            refreshedAt: .now
        )
    }
}

private extension WorkspacePlaybackSourceOpener {
    func openApplication(bundleIdentifier: String) -> Bool {
        guard let applicationURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) else {
            return false
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(
            at: applicationURL,
            configuration: configuration
        ) { application, _ in
            guard let application else { return }

            Task { @MainActor in
                self.showRunningApplication(application)
            }
        }

        return true
    }

    func showRunningApplication(_ application: NSRunningApplication) {
        application.unhide()
        application.activate(options: [.activateAllWindows])
    }
}
