import Combine
import CoreAudio
internal import AppKit

@MainActor
final class SoundControlModel: ObservableObject {
    @Published private(set) var volume: Double = 0
    @Published private(set) var isMuted = false
    @Published private(set) var canSetVolume = false
    @Published private(set) var canToggleMute = false
    @Published private(set) var routes: [AudioOutputRoute] = []
    @Published private(set) var currentRoute: AudioOutputRoute?
    @Published private(set) var routeChangeFailed = false
    @Published private(set) var volumeChangeFailed = false
    @Published private(set) var usesMonitorVolume = false

    private let audioService: SystemAudioVolumeService
    private let routing: any AudioOutputRouting
    private let volumeObserver: SystemAudioChangeObserver
    private let monitorController: any DisplayVolumeControlling
    private var monitorDisplayID: UInt32?
    private var monitorReadTask: Task<Void, Never>?
    private var monitorWriteTask: Task<Void, Never>?
    private var monitorPoll: Timer?
    private var pendingMonitorVolume: Double?
    private var lastAudibleMonitorVolume: [UInt32: Double] = [:]
    private var isObserving = false
    private lazy var routeListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        MainActor.assumeIsolated { self?.refresh() }
    }

    init(audioService: SystemAudioVolumeService, routing: (any AudioOutputRouting)? = nil, monitorController: (any DisplayVolumeControlling)? = nil) {
        self.audioService = audioService
        self.routing = routing ?? SystemAudioOutputRoutingService()
        self.monitorController = monitorController ?? DisplayDDCVolumeService()
        volumeObserver = SystemAudioChangeObserver(audioService: audioService)
        volumeObserver.onVolumeChange = { [weak self] _, _ in self?.refresh() }
    }

    isolated deinit {
        stopObserving()
        monitorReadTask?.cancel()
        monitorWriteTask?.cancel()
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        refresh()
        volumeObserver.startObserving()
        monitorPoll = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshMonitorVolume() }
        }
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, routeListener)
        }
    }

    func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        monitorPoll?.invalidate()
        monitorPoll = nil
        monitorReadTask?.cancel()
        monitorReadTask = nil
        volumeObserver.stopObserving()
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, routeListener)
        }
    }

    func refresh() {
        let previousRouteID = currentRoute?.id
        routes = routing.availableRoutes()
        currentRoute = routes.first(where: \.isCurrent)
        if previousRouteID != currentRoute?.id { resetMonitorControl() }
        if audioService.canSetVolume {
            resetMonitorControl()
            volume = Double(audioService.currentEffectiveVolume)
            canSetVolume = true
            canToggleMute = audioService.canToggleMute
            isMuted = audioService.isMuted || volume < 0.001
        } else {
            let displayID = matchingDisplayID()
            if displayID != monitorDisplayID { resetMonitorControl(); monitorDisplayID = displayID }
            if !usesMonitorVolume {
                volume = 0
                canSetVolume = false
                canToggleMute = audioService.canToggleMute
                isMuted = audioService.isMuted
            }
            refreshMonitorVolume()
        }
    }

    func setVolume(_ value: Double) {
        guard canSetVolume, value.isFinite else { return }
        volumeChangeFailed = false
        if usesMonitorVolume, let displayID = monitorDisplayID {
            volume = max(0, min(1, value))
            isMuted = volume < 0.001
            if !isMuted { lastAudibleMonitorVolume[displayID] = volume }
            pendingMonitorVolume = volume
            writePendingMonitorVolume(displayID: displayID)
            return
        }
        volume = Double(audioService.setVolume(Float(value))) / 100
        isMuted = audioService.isMuted || volume < 0.001
    }

    func toggleMute() {
        guard canToggleMute else { return }
        if usesMonitorVolume, let displayID = monitorDisplayID {
            setVolume(isMuted ? (lastAudibleMonitorVolume[displayID] ?? 0.25) : 0)
            return
        }
        _ = audioService.toggleMute()
        refresh()
    }

    func select(_ route: AudioOutputRoute) {
        routeChangeFailed = !routing.setCurrentRoute(route.id)
        refresh()
    }

    private func matchingDisplayID() -> UInt32? {
        guard let route = currentRoute,
              [kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort].contains(route.transportType) else { return nil }
        let matches = NSScreen.screens.filter {
            $0.localizedName.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(route.name.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
        }
        guard matches.count == 1,
              let number = matches[0].deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              CGDisplayIsBuiltin(number.uint32Value) == 0 else { return nil }
        return number.uint32Value
    }

    private func refreshMonitorVolume() {
        guard let displayID = monitorDisplayID, monitorReadTask == nil, monitorWriteTask == nil else { return }
        monitorReadTask = Task { [weak self, monitorController] in
            let result = await monitorController.readVolume(displayID: displayID)
            guard let self, !Task.isCancelled, monitorDisplayID == displayID else { return }
            monitorReadTask = nil
            guard monitorWriteTask == nil else { return }
            if let result { applyMonitorVolume(result) }
            else {
                usesMonitorVolume = false
                canSetVolume = false
                canToggleMute = audioService.canToggleMute
            }
        }
    }

    private func writePendingMonitorVolume(displayID: UInt32) {
        guard monitorWriteTask == nil else { return }
        monitorWriteTask = Task { [weak self, monitorController] in
            guard let self else { return }
            while let requested = pendingMonitorVolume, !Task.isCancelled, monitorDisplayID == displayID {
                pendingMonitorVolume = nil
                let result = await monitorController.setVolume(requested, displayID: displayID)
                guard !Task.isCancelled, monitorDisplayID == displayID else { return }
                if let result {
                    if pendingMonitorVolume == nil { applyMonitorVolume(result) }
                } else { volumeChangeFailed = true }
                // Keep dragging responsive while limiting traffic to the monitor.
                try? await Task.sleep(for: .milliseconds(80))
            }
            guard monitorDisplayID == displayID else { return }
            monitorWriteTask = nil
            if volumeChangeFailed { refreshMonitorVolume() }
        }
    }

    private func applyMonitorVolume(_ result: DisplayDDCVolume) {
        usesMonitorVolume = true
        canSetVolume = true
        canToggleMute = true
        volume = result.fraction
        isMuted = result.current == 0
        if !isMuted { lastAudibleMonitorVolume[result.displayID] = volume }
    }

    private func resetMonitorControl() {
        monitorReadTask?.cancel(); monitorReadTask = nil
        monitorWriteTask?.cancel(); monitorWriteTask = nil
        pendingMonitorVolume = nil
        monitorDisplayID = nil
        usesMonitorVolume = false
        volumeChangeFailed = false
    }
}
