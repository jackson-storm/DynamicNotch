import CoreAudio
import SwiftUI
@testable import DynamicNotch

final class TestNotchSettings: NotchSettingsProviding {
    var notchWidth: Int
    var notchHeight: Int
    var displayLocation: NotchDisplayLocation {
        didSet {
            screenSelectionPreferences = NotchScreenSelectionPreferences(
                displayLocation: displayLocation,
                preferredDisplayUUID: screenSelectionPreferences.preferredDisplayUUID,
                allowsAutomaticDisplaySwitching: screenSelectionPreferences.allowsAutomaticDisplaySwitching
            )
        }
    }
    var screenSelectionPreferences: NotchScreenSelectionPreferences
    var notchAnimationPreset: NotchAnimationPreset
    var isNotchTapToExpandEnabled: Bool
    var isNotchMouseDragGesturesEnabled: Bool
    var isNotchTrackpadSwipeGesturesEnabled: Bool
    var isNotchSwipeDismissEnabled: Bool
    var isNotchSwipeRestoreEnabled: Bool

    init(
        notchWidth: Int = 0,
        notchHeight: Int = 0,
        displayLocation: NotchDisplayLocation = .main,
        screenSelectionPreferences: NotchScreenSelectionPreferences? = nil,
        notchAnimationPreset: NotchAnimationPreset = .balanced,
        isNotchTapToExpandEnabled: Bool = true,
        isNotchMouseDragGesturesEnabled: Bool = true,
        isNotchTrackpadSwipeGesturesEnabled: Bool = true,
        isNotchSwipeDismissEnabled: Bool = true,
        isNotchSwipeRestoreEnabled: Bool = true
    ) {
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.displayLocation = displayLocation
        self.screenSelectionPreferences = screenSelectionPreferences ?? NotchScreenSelectionPreferences(
            displayLocation: displayLocation,
            preferredDisplayUUID: nil,
            allowsAutomaticDisplaySwitching: false
        )
        self.notchAnimationPreset = notchAnimationPreset
        self.isNotchTapToExpandEnabled = isNotchTapToExpandEnabled
        self.isNotchMouseDragGesturesEnabled = isNotchMouseDragGesturesEnabled
        self.isNotchTrackpadSwipeGesturesEnabled = isNotchTrackpadSwipeGesturesEnabled
        self.isNotchSwipeDismissEnabled = isNotchSwipeDismissEnabled
        self.isNotchSwipeRestoreEnabled = isNotchSwipeRestoreEnabled
    }
}

final class FakePowerStateProvider: PowerStateProviding {
    var onPowerStateChange: ((_ onACPower: Bool, _ batteryLevel: Int) -> Void)?

    var onACPower: Bool {
        didSet { notify() }
    }

    var batteryLevel: Int {
        didSet { notify() }
    }

    init(onACPower: Bool = false, batteryLevel: Int = 50) {
        self.onACPower = onACPower
        self.batteryLevel = batteryLevel
    }

    private func notify() {
        onPowerStateChange?(onACPower, batteryLevel)
    }
}

final class FakeNetworkMonitor: NetworkMonitoring {
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)?
    var currentWiFiName: String?
    var currentVPNName: String?

    private(set) var startCalls = 0
    private(set) var stopCalls = 0

    func startMonitoring() {
        startCalls += 1
    }

    func stopMonitoring() {
        stopCalls += 1
    }

    func send(
        wifi: Bool,
        hotspot: Bool,
        vpn: Bool,
        wifiName: String? = nil,
        vpnName: String? = nil
    ) {
        currentWiFiName = wifiName
        currentVPNName = vpnName
        onStatusChange?(wifi, hotspot, vpn)
    }
}

final class FakeNowPlayingService: NowPlayingMonitoring {
    var onSnapshotChange: ((NowPlayingSnapshot?) -> Void)?

    private(set) var startCalls = 0
    private(set) var stopCalls = 0
    private(set) var commands: [NowPlayingCommand] = []

    func startMonitoring() {
        startCalls += 1
    }

    func stopMonitoring() {
        stopCalls += 1
    }

    func send(_ command: NowPlayingCommand) {
        commands.append(command)
    }

    func publish(_ snapshot: NowPlayingSnapshot?) {
        onSnapshotChange?(snapshot)
    }
}

@MainActor
final class FakePlaybackSourceOpener: PlaybackSourceOpening {
    private(set) var openedSources: [NowPlayingPlaybackSource] = []

    func openPlaybackSource(_ source: NowPlayingPlaybackSource) {
        openedSources.append(source)
    }
}

final class FakeAudioOutputRoutingService: AudioOutputRouting {
    var routes: [AudioOutputRoute]
    private(set) var selectedRouteIDs: [AudioDeviceID] = []

    init(routes: [AudioOutputRoute] = []) {
        self.routes = routes
    }

    func availableRoutes() -> [AudioOutputRoute] {
        routes
    }

    func currentRoute() -> AudioOutputRoute? {
        routes.first(where: \.isCurrent)
    }

    @discardableResult
    func setCurrentRoute(_ id: AudioDeviceID) -> Bool {
        selectedRouteIDs.append(id)

        guard routes.contains(where: { $0.id == id }) else {
            return false
        }

        routes = routes.map { route in
            AudioOutputRoute(
                id: route.id,
                name: route.name,
                transportType: route.transportType,
                isCurrent: route.id == id
            )
        }

        return true
    }
}

final class FakeFileDownloadMonitor: DownloadMonitoring {
    var onSnapshotChange: (([DownloadModel]) -> Void)?

    private(set) var startCalls = 0
    private(set) var stopCalls = 0

    func startMonitoring() {
        startCalls += 1
    }

    func stopMonitoring() {
        stopCalls += 1
    }

    func publish(_ transfers: [DownloadModel]) {
        onSnapshotChange?(transfers)
    }
}

final class FakeLockScreenMonitoringService: LockScreenMonitoring {
    var onLockStateChange: ((Bool) -> Void)?

    private(set) var startCalls = 0
    private(set) var stopCalls = 0

    func startMonitoring() {
        startCalls += 1
    }

    func stopMonitoring() {
        stopCalls += 1
    }

    func publish(isLocked: Bool) {
        onLockStateChange?(isLocked)
    }
}

final class FakeLockScreenSoundPlayer: LockScreenSoundPlaying {
    enum Sound: Equatable {
        case lock
        case unlock
    }

    private(set) var playedSounds: [Sound] = []

    func playLock() {
        playedSounds.append(.lock)
    }

    func playUnlock() {
        playedSounds.append(.unlock)
    }
}

enum TestLifetime {
    private static var retainedObjects: [AnyObject] = []

    // XCTest is crashing while tearing down some MainActor-isolated view models in this target.
    static func retain(_ object: AnyObject) {
        retainedObjects.append(object)
    }
}

struct TestNotchContent: NotchContentProtocol {
    let id: String
    let priority: Int
    var strokeColor: Color = .clear
    var collapsedWidthOffset: CGFloat = 0
    var collapsedHeightOffset: CGFloat = 0
    var isExpandable: Bool = false
    var expandsOnTap: Bool = true
    var expandedWidthOffset: CGFloat = 0
    var expandedHeightOffset: CGFloat = 0

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: baseWidth + collapsedWidthOffset,
            height: baseHeight + collapsedHeightOffset
        )
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: baseWidth + expandedWidthOffset,
            height: baseHeight + expandedHeightOffset
        )
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(EmptyView())
    }
}

func makeNowPlayingSnapshot(
    title: String = "After Hours",
    artist: String = "The Weeknd",
    album: String = "After Hours",
    duration: TimeInterval = 243,
    elapsedTime: TimeInterval = 32,
    playbackRate: Double = 1,
    artworkData: Data? = nil,
    playbackSource: NowPlayingPlaybackSource? = nil,
    mediaType: String? = nil,
    contentItemIdentifier: String? = nil
) -> NowPlayingSnapshot {
    NowPlayingSnapshot(
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
        refreshedAt: .now
    )
}
