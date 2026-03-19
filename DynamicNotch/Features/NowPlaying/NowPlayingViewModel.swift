import AppKit
import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published private(set) var artworkPalette = NowPlayingArtworkPalette.fallback
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private var hasStartedMonitoring = false
    #if DEBUG
    private var isShowingDebugPreviewSnapshot = false
    #endif

    var hasActiveSession: Bool {
        snapshot != nil
    }

    convenience init() {
        self.init(service: MediaRemoteNowPlayingService())
    }

    init(service: any NowPlayingMonitoring) {
        self.service = service
        self.service.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.apply(snapshot: snapshot)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.apply(snapshot: snapshot)
                }
            }
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        service.startMonitoring()
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

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
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
    func apply(snapshot newSnapshot: NowPlayingSnapshot?, emitEvent: Bool = true) {
        let wasActive = snapshot != nil
        let artworkDidChange = snapshot?.artworkData != newSnapshot?.artworkData

        snapshot = newSnapshot

        if artworkDidChange {
            artworkImage = newSnapshot?.artworkData.flatMap(NSImage.init(data:))
            artworkPalette = NowPlayingArtworkPaletteExtractor.extract(from: newSnapshot?.artworkData)
        }

        let isActive = newSnapshot != nil

        if emitEvent {
            if !wasActive && isActive {
                event = .started
            } else if wasActive && !isActive {
                event = .stopped
            }
        }
    }
}

private extension NowPlayingSnapshot {
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
