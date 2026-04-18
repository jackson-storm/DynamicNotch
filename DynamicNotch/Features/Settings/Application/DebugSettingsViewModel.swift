//
//  DebugSettingsViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/21/26.
//

#if DEBUG
import SwiftUI
import Combine

@MainActor
final class DebugSettingsViewModel: ObservableObject {
    @Published var isOnboardingPreviewEnabled = false {
        didSet { guard isReady else { return }; updateOnboardingPreview() }
    }

    @Published var isFocusLivePreviewEnabled = false {
        didSet { guard isReady else { return }; updateFocusPreview() }
    }

    @Published var isHotspotPreviewEnabled = false {
        didSet { guard isReady else { return }; updateHotspotPreview() }
    }

    @Published var isNowPlayingPreviewEnabled = false {
        didSet { guard isReady else { return }; updateNowPlayingPreview() }
    }

    @Published var isDownloadPreviewEnabled = false {
        didSet { guard isReady else { return }; updateDownloadPreview() }
    }
    
    @Published var isTimerPreviewEnabled = false {
        didSet { guard isReady else { return }; updateTimerPreview() }
    }

    @Published var isLockScreenPreviewEnabled = false {
        didSet { guard isReady else { return }; updateLockScreenPreview() }
    }

    @Published private(set) var isPreviewSequenceRunning = false

    private static let sequenceContentPrefix = "debug.sequence."
    private static let sequenceFocusID = "debug.sequence.focus.on"
    private static let sequenceHotspotID = "debug.sequence.hotspot.active"
    private static let sequenceNowPlayingID = "debug.sequence.nowPlaying"
    private static let sequenceDownloadsID = "debug.sequence.download.active"
    private static let sequenceTimerID = "debug.sequence.clock.timer"
    private static let livePreviewDuration: TimeInterval = 4
    private static let previewGapDuration: TimeInterval = 1
    private static let transitionBufferDuration: TimeInterval = 0.35
    private static let waitPollInterval: UInt64 = 50_000_000
    private static let sequenceLiveActivityIDs = [
        sequenceFocusID,
        sequenceHotspotID,
        sequenceNowPlayingID,
        sequenceDownloadsID,
        sequenceTimerID
    ]

    private let notchViewModel: NotchViewModel
    private let notchEventCoordinator: NotchEventCoordinator
    private let bluetoothViewModel: BluetoothViewModel
    private let powerService: PowerService
    private let networkViewModel: NetworkViewModel
    private let downloadViewModel: DownloadViewModel
    private let timerViewModel: TimerViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let lockScreenManager: LockScreenManager
    private let settingsViewModel: SettingsViewModel

    private var isReady = false
    private var previewSequenceTask: Task<Void, Never>?

    init(
        notchViewModel: NotchViewModel,
        notchEventCoordinator: NotchEventCoordinator,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        networkViewModel: NetworkViewModel,
        downloadViewModel: DownloadViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.notchViewModel = notchViewModel
        self.notchEventCoordinator = notchEventCoordinator
        self.bluetoothViewModel = bluetoothViewModel
        self.powerService = powerService
        self.networkViewModel = networkViewModel
        self.downloadViewModel = downloadViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        self.isReady = true
    }

    func triggerBluetoothPreview() {
        applyBluetoothPreviewState()
        notchEventCoordinator.handleBluetoothEvent(.connected)
    }

    func triggerWifiPreview() {
        networkViewModel.wifiConnected = true
        networkViewModel.wifiName = "Debug Wi-Fi"
        notchEventCoordinator.handleNetworkEvent(.wifiConnected)
    }

    func triggerVPNPreview() {
        applyVPNPreviewState()
        notchEventCoordinator.handleNetworkEvent(.vpnConnected)
    }

    func triggerChargingPreview() {
        applyChargingPreviewState()
        notchEventCoordinator.handlePowerEvent(.charger)
    }

    func triggerLowPowerPreview() {
        applyLowPowerPreviewState()
        notchEventCoordinator.handlePowerEvent(.lowPower)
    }

    func triggerFullBatteryPreview() {
        applyFullBatteryPreviewState()
        notchEventCoordinator.handlePowerEvent(.fullPower)
    }

    func triggerFocusOffPreview() {
        isFocusLivePreviewEnabled = false
        notchEventCoordinator.handleFocusEvent(.FocusOff)
    }

    func triggerBrightnessHUDPreview() {
        notchEventCoordinator.handleHudEvent(.display(72))
    }

    func triggerKeyboardHUDPreview() {
        notchEventCoordinator.handleHudEvent(.keyboard(64))
    }

    func triggerVolumeHUDPreview() {
        notchEventCoordinator.handleHudEvent(.volume(42))
    }

    func triggerNotchWidthPreview() {
        notchEventCoordinator.handleNotchWidthEvent(.width)
    }

    func triggerNotchHeightPreview() {
        notchEventCoordinator.handleNotchWidthEvent(.height)
    }

    func togglePreviewSequence() {
        if isPreviewSequenceRunning {
            stopPreviewSequence()
        } else {
            startPreviewSequence()
        }
    }

    func hideCurrentTemporaryPreview() {
        notchViewModel.hideTemporaryNotification()
    }

    func resetAllPreviews() {
        stopPreviewSequence()
        isOnboardingPreviewEnabled = false
        isFocusLivePreviewEnabled = false
        isHotspotPreviewEnabled = false
        isNowPlayingPreviewEnabled = false
        isDownloadPreviewEnabled = false
        isTimerPreviewEnabled = false
        isLockScreenPreviewEnabled = false
        notchViewModel.hideTemporaryNotification()
    }

    private func updateOnboardingPreview() {
        if isOnboardingPreviewEnabled {
            notchEventCoordinator.showDebugOnboardingPreview(step: .first)
        } else {
            notchEventCoordinator.hideOnboarding()
        }
    }

    private func updateFocusPreview() {
        if isFocusLivePreviewEnabled {
            notchEventCoordinator.handleFocusEvent(.FocusOn)
        } else {
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
        }
    }

    private func updateHotspotPreview() {
        if isHotspotPreviewEnabled {
            networkViewModel.hotspotActive = true
            notchEventCoordinator.handleNetworkEvent(.hotspotActive)
        } else {
            networkViewModel.hotspotActive = false
            notchEventCoordinator.handleNetworkEvent(.hotspotHide)
        }
    }

    private func updateNowPlayingPreview() {
        if isNowPlayingPreviewEnabled {
            nowPlayingViewModel.showDebugPreviewSnapshotIfNeeded()
            notchEventCoordinator.handleNowPlayingEvent(.started)
        } else {
            notchEventCoordinator.handleNowPlayingEvent(.stopped)
            nowPlayingViewModel.hideDebugPreviewSnapshotIfNeeded()
        }
    }

    private func updateDownloadPreview() {
        if isDownloadPreviewEnabled {
            downloadViewModel.showDebugPreviewDownloadsIfNeeded()
            notchEventCoordinator.handleDownloadEvent(.started)
        } else {
            downloadViewModel.hideDebugPreviewDownloadsIfNeeded()

            if downloadViewModel.hasActiveDownloads {
                notchEventCoordinator.handleDownloadEvent(.started)
            } else {
                notchEventCoordinator.handleDownloadEvent(.stopped)
            }
        }
    }
    
    private func updateTimerPreview() {
        if isTimerPreviewEnabled {
            timerViewModel.showDebugPreviewSnapshotIfNeeded()
            notchEventCoordinator.handleTimerEvent(.started)
        } else {
            notchEventCoordinator.handleTimerEvent(.stopped)
            timerViewModel.hideDebugPreviewSnapshotIfNeeded()
        }
    }

    private func updateLockScreenPreview() {
        lockScreenManager.setDebugLockState(isLockScreenPreviewEnabled)
        notchEventCoordinator.handleLockScreenEvent(
            isLockScreenPreviewEnabled ? .started : .stopped
        )
    }

    private func startPreviewSequence() {
        stopPreviewSequence()

        previewSequenceTask = Task { [weak self] in
            guard let self else { return }

            self.isPreviewSequenceRunning = true
            self.clearPreviewSequenceArtifacts()

            defer {
                self.clearPreviewSequenceArtifacts()
                self.isPreviewSequenceRunning = false
                self.previewSequenceTask = nil
            }

            do {
                try await self.playLivePreview(
                    FocusOnNotchContent(settingsViewModel: settingsViewModel),
                    id: Self.sequenceFocusID
                )
                try await self.playTemporaryPreview(
                    FocusOffNotchContent(settingsViewModel: settingsViewModel),
                    id: "\(Self.sequenceContentPrefix)focus.off",
                    duration: 3
                )
                try await self.playLivePreview(
                    HotspotActiveContent(settingsViewModel: settingsViewModel),
                    id: Self.sequenceHotspotID
                )
                try await self.playNowPlayingPreview()
                try await self.playDownloadsPreview()
                try await self.playTimerPreview()
                try await self.playBluetoothPreview()
                try await self.playTemporaryPreview(
                    WifiConnectedNotchContent(
                        networkViewModel: networkViewModel
                    ),
                    id: "\(Self.sequenceContentPrefix)wifi.connected",
                    duration: 3
                )
                try await self.playVPNPreview()
                try await self.playChargingPreview()
                try await self.playLowPowerPreview()
                try await self.playFullBatteryPreview()
                try await self.playTemporaryPreview(
                    HudNotchContent(
                        kind: .brightness,
                        level: 72,
                        applicationSettings: settingsViewModel.application
                    ),
                    id: "\(Self.sequenceContentPrefix)hud.brightness",
                    duration: 2
                )
                try await self.playTemporaryPreview(
                    HudNotchContent(
                        kind: .keyboard,
                        level: 64,
                        applicationSettings: settingsViewModel.application
                    ),
                    id: "\(Self.sequenceContentPrefix)hud.keyboard",
                    duration: 2
                )
                try await self.playTemporaryPreview(
                    HudNotchContent(
                        kind: .volume,
                        level: 42,
                        applicationSettings: settingsViewModel.application
                    ),
                    id: "\(Self.sequenceContentPrefix)hud.volume",
                    duration: 2
                )
            } catch is CancellationError {
            } catch {
            }
        }
    }

    private func stopPreviewSequence() {
        previewSequenceTask?.cancel()
        previewSequenceTask = nil
        isPreviewSequenceRunning = false
        clearPreviewSequenceArtifacts()
    }

    private func playBluetoothPreview() async throws {
        applyBluetoothPreviewState()
        try await playTemporaryPreview(
            BluetoothConnectedNotchContent(
                bluetoothViewModel: bluetoothViewModel,
                settings: settingsViewModel.connectivity,
                applicationSettings: settingsViewModel.application
            ),
            id: "\(Self.sequenceContentPrefix)bluetooth.connected",
            duration: 5
        )
    }

    private func playVPNPreview() async throws {
        applyVPNPreviewState()
        try await playTemporaryPreview(
            VpnConnectedNotchContent(
                networkViewModel: networkViewModel,
                settings: settingsViewModel.connectivity
            ),
            id: "\(Self.sequenceContentPrefix)vpn.connected",
            duration: 5
        )
    }

    private func playChargingPreview() async throws {
        applyChargingPreviewState()
        try await playTemporaryPreview(
            ChargerNotchContent(
                powerService: powerService,
                settingsViewModel: settingsViewModel
            ),
            id: "\(Self.sequenceContentPrefix)charger",
            duration: 4
        )
    }

    private func playLowPowerPreview() async throws {
        applyLowPowerPreviewState()
        try await playTemporaryPreview(
            LowPowerNotchContent(
                powerService: powerService,
                settingsViewModel: settingsViewModel
            ),
            id: "\(Self.sequenceContentPrefix)lowPower",
            duration: 4
        )
    }

    private func playFullBatteryPreview() async throws {
        applyFullBatteryPreviewState()
        try await playTemporaryPreview(
            FullPowerNotchContent(
                powerService: powerService,
                settingsViewModel: settingsViewModel
            ),
            id: "\(Self.sequenceContentPrefix)fullPower",
            duration: 4
        )
    }

    private func playNowPlayingPreview() async throws {
        nowPlayingViewModel.showDebugPreviewSnapshotIfNeeded()
        try await playLivePreview(
            NowPlayingNotchContent(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: settingsViewModel.mediaAndFiles,
                applicationSettings: settingsViewModel.application
            ),
            id: Self.sequenceNowPlayingID
        )
        nowPlayingViewModel.hideDebugPreviewSnapshotIfNeeded()

        if isNowPlayingPreviewEnabled {
            updateNowPlayingPreview()
        }
    }

    private func playDownloadsPreview() async throws {
        downloadViewModel.showDebugPreviewDownloadsIfNeeded()
        try await playLivePreview(
            DownloadNotchContent(
                downloadViewModel: downloadViewModel,
                settingsViewModel: settingsViewModel
            ),
            id: Self.sequenceDownloadsID
        )
        downloadViewModel.hideDebugPreviewDownloadsIfNeeded()

        if isDownloadPreviewEnabled {
            updateDownloadPreview()
        }
    }

    private func playTimerPreview() async throws {
        timerViewModel.showDebugPreviewSnapshotIfNeeded()
        try await playLivePreview(
            TimerNotchContent(
                timerViewModel: timerViewModel
            ),
            id: Self.sequenceTimerID
        )
        timerViewModel.hideDebugPreviewSnapshotIfNeeded()

        if isTimerPreviewEnabled {
            updateTimerPreview()
        }
    }

    private func playTemporaryPreview(
        _ content: any NotchContentProtocol,
        id: String,
        duration: TimeInterval
    ) async throws {
        notchViewModel.send(
            .showTemporaryNotification(
                makeSequenceContent(content, id: id),
                duration: duration
            )
        )

        try await waitUntil {
            self.notchViewModel.notchModel.temporaryNotificationContent?.id == id
        }
        try await pause(for: duration)
        try await waitUntil {
            self.notchViewModel.notchModel.temporaryNotificationContent?.id != id
        }
        try await pause(for: Self.transitionBufferDuration)
        try await pause(for: Self.previewGapDuration)
    }

    private func playLivePreview(
        _ content: any NotchContentProtocol,
        id: String
    ) async throws {
        try await playLivePreview(
            content,
            id: id,
            duration: Self.livePreviewDuration
        )
    }

    private func playLivePreview(
        _ content: any NotchContentProtocol,
        id: String,
        duration: TimeInterval
    ) async throws {
        notchViewModel.send(
            .showLiveActivity(
                makeSequenceContent(content, id: id, priorityBoost: 1_000)
            )
        )

        try await waitUntil {
            self.notchViewModel.notchModel.liveActivityContent?.id == id
        }
        try await pause(for: duration)

        notchViewModel.send(.hideLiveActivity(id: id))

        try await waitUntil {
            self.notchViewModel.notchModel.liveActivityContent?.id != id
        }
        try await pause(for: Self.transitionBufferDuration)
        try await pause(for: Self.previewGapDuration)
    }

    private func clearPreviewSequenceArtifacts() {
        if let currentTemporaryID = notchViewModel.notchModel.temporaryNotificationContent?.id,
           currentTemporaryID.hasPrefix(Self.sequenceContentPrefix) {
            notchViewModel.hideTemporaryNotification()
        }

        Self.sequenceLiveActivityIDs.forEach { id in
            notchViewModel.send(.hideLiveActivity(id: id))
        }

        nowPlayingViewModel.hideDebugPreviewSnapshotIfNeeded()
        downloadViewModel.hideDebugPreviewDownloadsIfNeeded()
        timerViewModel.hideDebugPreviewSnapshotIfNeeded()

        if isNowPlayingPreviewEnabled {
            updateNowPlayingPreview()
        }

        if isDownloadPreviewEnabled {
            updateDownloadPreview()
        }

        if isTimerPreviewEnabled {
            updateTimerPreview()
        }
    }

    private func makeSequenceContent(
        _ content: any NotchContentProtocol,
        id: String,
        priorityBoost: Int = 0
    ) -> DebugSequenceNotchContent {
        DebugSequenceNotchContent(
            id: id,
            priority: content.priority + priorityBoost,
            base: content
        )
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool
    ) async throws {
        while !condition() {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: Self.waitPollInterval)
        }
    }

    private func pause(for duration: TimeInterval) async throws {
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        try Task.checkCancellation()
    }

    private func applyBluetoothPreviewState() {
        bluetoothViewModel.isConnected = true
        bluetoothViewModel.deviceName = "AirPods Pro"
        bluetoothViewModel.batteryLevel = 76
        bluetoothViewModel.deviceType = .airpodsPro
    }

    private func applyVPNPreviewState() {
        networkViewModel.vpnConnected = true
        networkViewModel.vpnName = "WireGuard Tunnel"
        networkViewModel.vpnConnectedAt = .now.addingTimeInterval(-513)
    }

    private func applyChargingPreviewState() {
        powerService.applyDebugState(
            onACPower: true,
            batteryLevel: 67,
            isCharging: true,
            isLowPowerMode: false
        )
    }

    private func applyLowPowerPreviewState() {
        powerService.applyDebugState(
            onACPower: false,
            batteryLevel: 14,
            isCharging: false,
            isLowPowerMode: false
        )
    }

    private func applyFullBatteryPreviewState() {
        powerService.applyDebugState(
            onACPower: true,
            batteryLevel: 100,
            isCharging: false,
            isLowPowerMode: false
        )
    }
}
#endif
