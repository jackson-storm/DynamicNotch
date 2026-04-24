internal import AppKit
import Combine
import SwiftUI

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
    @Published private(set) var audioReactiveLevels = Array(repeating: CGFloat(0), count: 5)
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private let audioOutputRouting: any AudioOutputRouting
    private let favoritesStore: UserDefaults
    private let mediaSettings: MediaAndFilesSettingsStore
    private let audioLevelMonitor: any NowPlayingAudioLevelMonitoring
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
    private var activeAudioReactiveVisualizationSources = Set<String>()
    private var cancellables = Set<AnyCancellable>()
    #if DEBUG
    private var isShowingDebugPreviewSnapshot = false
    #endif

    var hasActiveSession: Bool {
        snapshot != nil
    }

    private static let emptyReactiveLevels = Array(repeating: CGFloat(0), count: 5)

    convenience init() {
        self.init(
            service: MediaRemoteNowPlayingService(),
            audioOutputRouting: SystemAudioOutputRoutingService(),
            favoritesStore: .standard,
            mediaSettings: MediaAndFilesSettingsStore(defaults: .standard),
            audioLevelMonitor: SystemNowPlayingAudioLevelMonitor()
        )
    }

    init(
        service: any NowPlayingMonitoring,
        audioOutputRouting: (any AudioOutputRouting)? = nil,
        favoritesStore: UserDefaults = .standard,
        mediaSettings: MediaAndFilesSettingsStore? = nil,
        audioLevelMonitor: (any NowPlayingAudioLevelMonitoring)? = nil
    ) {
        self.service = service
        self.audioOutputRouting = audioOutputRouting ?? InactiveAudioOutputRoutingService()
        self.favoritesStore = favoritesStore
        self.mediaSettings = mediaSettings ?? MediaAndFilesSettingsStore(defaults: favoritesStore)
        self.audioLevelMonitor = audioLevelMonitor ?? SystemNowPlayingAudioLevelMonitor()
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
        self.audioLevelMonitor.onLevelsChange = { [weak self] levels in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.audioReactiveLevels = levels
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.audioReactiveLevels = levels
                }
            }
        }
        bindAudioReactiveMonitoring()
        refreshAudioOutputRoutes()
    }

    deinit {
        let monitor = audioLevelMonitor
        Task { @MainActor in
            monitor.stopMonitoring()
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        ignoresServiceSnapshots = false
        service.startMonitoring()
        updateAudioReactiveMonitoringState()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false
        ignoresServiceSnapshots = true
        service.stopMonitoring()
        cancelPendingSessionEnd()
        cancelPendingArtworkPresentation()
        apply(snapshot: nil)
    }

    func togglePlayPause() {
        if let snapshot {
            apply(snapshot: snapshot.togglingPlaybackState())
        }

        service.send(.togglePlayPause)
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
        snapshot?.favoriteTrackKey != nil
    }

    func toggleFavorite() {
        guard let favoriteTrackKey = snapshot?.favoriteTrackKey else { return }

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

    func setAudioReactiveVisualizationActive(_ isActive: Bool, source: String) {
        if isActive {
            activeAudioReactiveVisualizationSources.insert(source)
        } else {
            activeAudioReactiveVisualizationSources.remove(source)
        }

        updateAudioReactiveMonitoringState()
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

    func bindAudioReactiveMonitoring() {
        mediaSettings.$nowPlayingEqualizerMode
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateAudioReactiveMonitoringState()
            }
            .store(in: &cancellables)
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
        isCurrentTrackFavorite = newSnapshot?.favoriteTrackKey.map(storedFavoriteTrackKeys.contains) ?? false

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

        updateAudioReactiveMonitoringState()
    }

    func updateAudioReactiveMonitoringState() {
        let shouldUseAudioReactiveMonitoring =
            hasStartedMonitoring &&
            !activeAudioReactiveVisualizationSources.isEmpty &&
            mediaSettings.nowPlayingEqualizerMode == .audioReactive &&
            snapshot?.isPlaying == true

        if shouldUseAudioReactiveMonitoring {
            audioLevelMonitor.startMonitoring()
        } else {
            audioLevelMonitor.stopMonitoring()

            if audioReactiveLevels != Self.emptyReactiveLevels {
                audioReactiveLevels = Self.emptyReactiveLevels
            }
        }
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
            refreshedAt: .now
        )
    }
}
