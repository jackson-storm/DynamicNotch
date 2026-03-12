import AppKit
import Combine
import SwiftUI

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var snapshot: NowPlayingSnapshot?
    @Published private(set) var artworkImage: NSImage?
    @Published var event: NowPlayingEvent?

    private var service: any NowPlayingMonitoring
    private var hasStartedMonitoring = false

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
        service.send(.togglePlayPause)
    }

    func nextTrack() {
        service.send(.nextTrack)
    }

    func previousTrack() {
        service.send(.previousTrack)
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        snapshot?.elapsedTime(at: date) ?? 0
    }
}

private extension NowPlayingViewModel {
    func apply(snapshot newSnapshot: NowPlayingSnapshot?) {
        let wasActive = snapshot != nil
        let artworkDidChange = snapshot?.artworkData != newSnapshot?.artworkData

        snapshot = newSnapshot

        if artworkDidChange {
            artworkImage = newSnapshot?.artworkData.flatMap(NSImage.init(data:))
        }

        let isActive = newSnapshot != nil

        if !wasActive && isActive {
            event = .started
        } else if wasActive && !isActive {
            event = .stopped
        }
    }
}
