import SwiftUI
@testable import DynamicNotch

final class TestNotchSettings: NotchSettingsProviding {
    var notchWidth: Int
    var notchHeight: Int
    var displayLocation: NotchDisplayLocation

    init(
        notchWidth: Int = 0,
        notchHeight: Int = 0,
        displayLocation: NotchDisplayLocation = .main
    ) {
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.displayLocation = displayLocation
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

    private(set) var startCalls = 0
    private(set) var stopCalls = 0

    func startMonitoring() {
        startCalls += 1
    }

    func stopMonitoring() {
        stopCalls += 1
    }

    func send(wifi: Bool, hotspot: Bool, vpn: Bool) {
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
    var offsetYTransition: CGFloat = 0

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }

    @MainActor
    func makeView() -> AnyView {
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
    artworkData: Data? = nil
) -> NowPlayingSnapshot {
    NowPlayingSnapshot(
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        elapsedTime: elapsedTime,
        playbackRate: playbackRate,
        artworkData: artworkData,
        refreshedAt: .now
    )
}
