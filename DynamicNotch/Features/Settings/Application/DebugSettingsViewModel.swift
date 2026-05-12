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

    @Published var isScreenRecordingPreviewEnabled = false {
        didSet { guard isReady else { return }; updateScreenRecordingPreview() }
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

    @Published var isFileTrayPreviewEnabled = false {
        didSet { guard isReady else { return }; updateFileTrayPreview() }
    }

    @Published var isFileConverterPreviewEnabled = false {
        didSet { guard isReady else { return }; updateFileConverterPreview() }
    }

    @Published var isLockScreenPreviewEnabled = false {
        didSet { guard isReady else { return }; updateLockScreenPreview() }
    }

    @Published private(set) var isPreviewSequenceRunning = false

    private static let sequenceContentPrefix = NotchContentRegistry.DebugSequence.prefix
    private static let sequenceFocusID = NotchContentRegistry.DebugSequence.focus
    private static let sequenceScreenRecordingID = NotchContentRegistry.DebugSequence.screenRecording
    private static let sequenceHotspotID = NotchContentRegistry.DebugSequence.hotspot
    private static let sequenceNowPlayingID = NotchContentRegistry.DebugSequence.nowPlaying
    private static let sequenceDownloadsID = NotchContentRegistry.DebugSequence.download
    private static let sequenceTimerID = NotchContentRegistry.DebugSequence.timer
    private static let sequenceAirDropID = NotchContentRegistry.DebugSequence.airDrop
    private static let sequenceTrayID = NotchContentRegistry.DebugSequence.tray
    private static let sequenceFileConverterID = NotchContentRegistry.DebugSequence.fileConverter
    private static let sequenceCombinedDropID = NotchContentRegistry.DebugSequence.combinedDrop
    private static let sequenceTrayActiveID = NotchContentRegistry.DebugSequence.trayActive
    private static let sequenceFileConverterActiveID = NotchContentRegistry.DebugSequence.fileConverterActive
    private static let sequenceLockScreenID = NotchContentRegistry.DebugSequence.lockScreen
    private static let livePreviewDuration: TimeInterval = 4
    private static let previewGapDuration: TimeInterval = 1
    private static let transitionBufferDuration: TimeInterval = 0.35
    private static let waitPollInterval: UInt64 = 50_000_000
    private static let sequenceLiveActivityIDs = [
        sequenceFocusID,
        sequenceScreenRecordingID,
        sequenceHotspotID,
        sequenceNowPlayingID,
        sequenceDownloadsID,
        sequenceTimerID,
        sequenceAirDropID,
        sequenceTrayID,
        sequenceFileConverterID,
        sequenceCombinedDropID,
        sequenceTrayActiveID,
        sequenceFileConverterActiveID,
        sequenceLockScreenID
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
    private let dragAndDropPreviewViewModel = AirDropNotchViewModel()
    private let fileTrayPreviewViewModel: FileTrayViewModel
    private let fileConverterPreviewViewModel = FileConverterViewModel()

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
        let previewDefaults = UserDefaults(
            suiteName: "DynamicNotch.Debug.Previews.\(UUID().uuidString)"
        ) ?? .standard
        self.fileTrayPreviewViewModel = FileTrayViewModel(defaults: previewDefaults)
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

    func triggerNoInternetConnectionPreview() {
        notchEventCoordinator.handleNetworkEvent(.noInternetConnection)
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

    func triggerNowPlayingPausePreview() {
        nowPlayingViewModel.showDebugPreviewSnapshotIfNeeded()
        notchEventCoordinator.handleNowPlayingEvent(.started)
        nowPlayingViewModel.pause()
        notchEventCoordinator.handleNowPlayingEvent(.playbackStateChanged(isPlaying: false))
    }

    func triggerNowPlayingPlayPreview() {
        nowPlayingViewModel.showDebugPreviewSnapshotIfNeeded()
        notchEventCoordinator.handleNowPlayingEvent(.started)
        nowPlayingViewModel.play()
        notchEventCoordinator.handleNowPlayingEvent(.playbackStateChanged(isPlaying: true))
    }

    func triggerNowPlayingStoppedPreview() {
        notchEventCoordinator.handleNowPlayingEvent(.stopped)
        nowPlayingViewModel.hideDebugPreviewSnapshotIfNeeded()
        isNowPlayingPreviewEnabled = false
    }

    func triggerDownloadStoppedPreview() {
        downloadViewModel.hideDebugPreviewDownloadsIfNeeded()
        notchEventCoordinator.handleDownloadEvent(.stopped)
        isDownloadPreviewEnabled = false
    }

    func triggerTimerUpdatedPreview() {
        timerViewModel.showDebugPreviewSnapshotIfNeeded()
        notchEventCoordinator.handleTimerEvent(.updated)
    }

    func triggerTimerStoppedPreview() {
        notchEventCoordinator.handleTimerEvent(.stopped)
        timerViewModel.hideDebugPreviewSnapshotIfNeeded()
        isTimerPreviewEnabled = false
    }

    func triggerScreenRecordingStoppedPreview() {
        notchEventCoordinator.handleScreenRecordingEvent(.stopped)
        isScreenRecordingPreviewEnabled = false
    }

    func triggerHotspotHidePreview() {
        networkViewModel.hotspotActive = false
        notchEventCoordinator.handleNetworkEvent(.hotspotHide)
        isHotspotPreviewEnabled = false
    }

    func triggerLockScreenStoppedPreview() {
        lockScreenManager.setDebugLockState(false)
        notchEventCoordinator.handleLockScreenEvent(.stopped)
        isLockScreenPreviewEnabled = false
    }

    func triggerAirDropTargetPreview() {
        showDragAndDropTargetPreview(.airDrop)
    }

    func triggerTrayTargetPreview() {
        showDragAndDropTargetPreview(.tray)
    }

    func triggerFileConverterTargetPreview() {
        showDragAndDropTargetPreview(.fileConverter)
    }

    func triggerCombinedDragAndDropPreview() {
        showCombinedDragAndDropPreview()
    }

    func triggerDragAndDropEndedPreview() {
        dragAndDropPreviewViewModel.setDraggingFile(false)
        hideDragAndDropTargetPreviews()
        notchEventCoordinator.handleAirDropEvent(.dragEnded)
    }

    func triggerDragAndDropDroppedPreview() {
        dragAndDropPreviewViewModel.handleSuccessfulDrop()
        hideDragAndDropTargetPreviews()
        notchEventCoordinator.handleAirDropEvent(.dropped)
    }

    func triggerFileConverterConvertedPreview() {
        showFileConverterStatusPreview {
            fileConverterPreviewViewModel.convert(options: fileConverterDebugConversionOptions)
        }
    }

    func triggerFileConverterConvertingPreview() {
        showFileConverterStatusPreview {
            fileConverterPreviewViewModel.showDebugConvertingStatus()
        }
    }

    func triggerFileConverterFailedPreview() {
        showFileConverterStatusPreview {
            fileConverterPreviewViewModel.showDebugFailedStatus()
        }
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
        isScreenRecordingPreviewEnabled = false
        isHotspotPreviewEnabled = false
        isNowPlayingPreviewEnabled = false
        isDownloadPreviewEnabled = false
        isTimerPreviewEnabled = false
        isFileTrayPreviewEnabled = false
        isFileConverterPreviewEnabled = false
        isLockScreenPreviewEnabled = false
        hideDragAndDropTargetPreviews()
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
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Focus.active.id))
        }
    }

    private func updateScreenRecordingPreview() {
        if isScreenRecordingPreviewEnabled {
            notchEventCoordinator.handleScreenRecordingEvent(.started)
        } else {
            notchEventCoordinator.handleScreenRecordingEvent(.stopped)
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

    private func updateFileTrayPreview() {
        if isFileTrayPreviewEnabled {
            showFileTrayActivePreview()
        } else {
            notchViewModel.send(.hideLiveActivity(id: Self.sequenceTrayActiveID))
            fileTrayPreviewViewModel.clear()
        }
    }

    private func updateFileConverterPreview() {
        if isFileConverterPreviewEnabled {
            showFileConverterActivePreview()
        } else {
            notchViewModel.send(.hideLiveActivity(id: Self.sequenceFileConverterActiveID))
            fileConverterPreviewViewModel.clear()
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
                    DebugOnboardingPreviewNotchContent(
                        step: .first,
                        notchEventCoordinator: notchEventCoordinator
                    ),
                    id: NotchContentRegistry.DebugSequence.onboarding
                )
                try await self.playLivePreview(
                    FocusOnNotchContent(settingsViewModel: settingsViewModel),
                    id: Self.sequenceFocusID
                )
                try await self.playLivePreview(
                    ScreenRecordingContent(settingsViewModel: settingsViewModel),
                    id: Self.sequenceScreenRecordingID
                )
                try await self.playTemporaryPreview(
                    FocusOffNotchContent(settingsViewModel: settingsViewModel),
                    id: NotchContentRegistry.DebugSequence.focusOff,
                    duration: 3
                )
                try await self.playLivePreview(
                    HotspotActiveContent(settingsViewModel: settingsViewModel),
                    id: Self.sequenceHotspotID
                )
                try await self.playNowPlayingPreview()
                try await self.playDownloadsPreview()
                try await self.playTimerPreview()
                try await self.playDragAndDropTargetPreview(
                    .airDrop,
                    id: Self.sequenceAirDropID
                )
                try await self.playDragAndDropTargetPreview(
                    .tray,
                    id: Self.sequenceTrayID
                )
                try await self.playDragAndDropTargetPreview(
                    .fileConverter,
                    id: Self.sequenceFileConverterID
                )
                try await self.playCombinedDragAndDropPreview()
                try await self.playFileTrayActivePreview()
                try await self.playFileConverterActivePreview()
                try await self.playFileConverterConvertingPreview()
                try await self.playFileConverterFailedPreview()
                try await self.playFileConverterConvertedPreview()
                try await self.playBluetoothPreview()
                try await self.playTemporaryPreview(
                    WifiConnectedNotchContent(
                        networkViewModel: networkViewModel
                    ),
                    id: NotchContentRegistry.DebugSequence.wifi,
                    duration: 3
                )
                try await self.playTemporaryPreview(
                    NoInternetConnectionContent(
                        onDismiss: { [weak self] in
                            self?.notchViewModel.hideTemporaryNotification()
                        }
                    ),
                    id: NotchContentRegistry.DebugSequence.noInternet,
                    duration: 5
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
                    id: NotchContentRegistry.DebugSequence.hudBrightness,
                    duration: 2
                )
                try await self.playTemporaryPreview(
                    HudNotchContent(
                        kind: .keyboard,
                        level: 64,
                        applicationSettings: settingsViewModel.application
                    ),
                    id: NotchContentRegistry.DebugSequence.hudKeyboard,
                    duration: 2
                )
                try await self.playTemporaryPreview(
                    HudNotchContent(
                        kind: .volume,
                        level: 42,
                        applicationSettings: settingsViewModel.application
                    ),
                    id: NotchContentRegistry.DebugSequence.hudVolume,
                    duration: 2
                )
                try await self.playTemporaryPreview(
                    NotchSizeWidthNotchContent(settingsViewModel: settingsViewModel),
                    id: NotchContentRegistry.DebugSequence.notchSizeWidth,
                    duration: 3
                )
                try await self.playTemporaryPreview(
                    NotchSizeHeightNotchContent(settingsViewModel: settingsViewModel),
                    id: NotchContentRegistry.DebugSequence.notchSizeHeight,
                    duration: 3
                )
                try await self.playLockScreenPreview()
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

    private func showDragAndDropTargetPreview(_ target: DragAndDropTarget) {
        dragAndDropPreviewViewModel.setDraggingFile(true)
        dragAndDropPreviewViewModel.setTargetedDropTarget(target)

        let id: String
        switch target {
        case .airDrop:
            id = Self.sequenceAirDropID
        case .tray:
            id = Self.sequenceTrayID
        case .fileConverter:
            id = Self.sequenceFileConverterID
        }

        notchViewModel.send(
            .showLiveActivity(
                makeSequenceContent(
                    makeDragAndDropTargetContent(for: target),
                    id: id,
                    priorityBoost: 1_000
                )
            )
        )
    }

    private func showCombinedDragAndDropPreview() {
        dragAndDropPreviewViewModel.setDraggingFile(true)
        dragAndDropPreviewViewModel.setTargetedDropTarget(.fileConverter)
        notchViewModel.send(
            .showLiveActivity(
                makeSequenceContent(
                    DragAndDropCombinedNotchContent(
                        airDropViewModel: dragAndDropPreviewViewModel,
                        settingsViewModel: settingsViewModel
                    ),
                    id: Self.sequenceCombinedDropID,
                    priorityBoost: 1_000
                )
            )
        )
    }

    private func hideDragAndDropTargetPreviews() {
        [
            Self.sequenceAirDropID,
            Self.sequenceTrayID,
            Self.sequenceFileConverterID,
            Self.sequenceCombinedDropID
        ].forEach { id in
            notchViewModel.send(.hideLiveActivity(id: id))
        }
    }

    private func makeDragAndDropTargetContent(for target: DragAndDropTarget) -> any NotchContentProtocol {
        switch target {
        case .airDrop:
            return AirDropNotchContent(
                airDropViewModel: dragAndDropPreviewViewModel,
                settingsViewModel: settingsViewModel
            )

        case .tray:
            return TrayNotchContent(
                airDropViewModel: dragAndDropPreviewViewModel,
                settingsViewModel: settingsViewModel
            )

        case .fileConverter:
            return FileConverterNotchContent(
                airDropViewModel: dragAndDropPreviewViewModel,
                settingsViewModel: settingsViewModel
            )
        }
    }

    private func showFileTrayActivePreview() {
        do {
            try prepareFileTrayPreviewItems()
            notchViewModel.send(
                .showLiveActivity(
                    makeSequenceContent(
                        TrayActiveNotchContent(
                            fileTrayViewModel: fileTrayPreviewViewModel,
                            mediaSettings: settingsViewModel.mediaAndFiles
                        ),
                        id: Self.sequenceTrayActiveID,
                        priorityBoost: 1_000
                    )
                )
            )
        } catch {
            isFileTrayPreviewEnabled = false
        }
    }

    private func showFileConverterActivePreview() {
        do {
            try prepareFileConverterPreviewItem()
            notchViewModel.send(
                .showLiveActivity(
                    makeSequenceContent(
                        makeFileConverterActivePreviewContent(),
                        id: Self.sequenceFileConverterActiveID,
                        priorityBoost: 1_000
                    )
                )
            )
        } catch {
            isFileConverterPreviewEnabled = false
        }
    }

    private func showFileConverterStatusPreview(_ configureStatus: () -> Void) {
        if isFileConverterPreviewEnabled {
            isFileConverterPreviewEnabled = false
        }

        do {
            try prepareFileConverterPreviewItem()
            configureStatus()
            notchViewModel.send(
                .showLiveActivity(
                    makeSequenceContent(
                        makeFileConverterActivePreviewContent(),
                        id: Self.sequenceFileConverterActiveID,
                        priorityBoost: 1_000
                    )
                )
            )
        } catch {
            fileConverterPreviewViewModel.clear()
        }
    }

    private func makeFileConverterActivePreviewContent() -> FileConverterActiveNotchContent {
        FileConverterActiveNotchContent(
            fileConverterViewModel: fileConverterPreviewViewModel,
            mediaSettings: settingsViewModel.mediaAndFiles,
            onRequestCollapse: { [weak notchViewModel] in
                notchViewModel?.handleOutsideClick()
            }
        )
    }

    private var fileConverterDebugConversionOptions: FileConverterConversionOptions {
        var options = FileConverterConversionOptions(settings: settingsViewModel.mediaAndFiles)
        options.outputLocation = .sameFolder
        options.existingFileBehavior = .createUniqueName
        return options
    }

    private func playBluetoothPreview() async throws {
        applyBluetoothPreviewState()
        try await playTemporaryPreview(
            BluetoothConnectedNotchContent(
                bluetoothViewModel: bluetoothViewModel,
                settings: settingsViewModel.connectivity,
                applicationSettings: settingsViewModel.application
            ),
            id: NotchContentRegistry.DebugSequence.bluetooth,
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
            id: NotchContentRegistry.DebugSequence.vpn,
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
            id: NotchContentRegistry.DebugSequence.charging,
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
            id: NotchContentRegistry.DebugSequence.lowPower,
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
            id: NotchContentRegistry.DebugSequence.fullPower,
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
                timerViewModel: timerViewModel,
                settingsViewModel: settingsViewModel
            ),
            id: Self.sequenceTimerID
        )
        timerViewModel.hideDebugPreviewSnapshotIfNeeded()

        if isTimerPreviewEnabled {
            updateTimerPreview()
        }
    }

    private func playDragAndDropTargetPreview(
        _ target: DragAndDropTarget,
        id: String
    ) async throws {
        dragAndDropPreviewViewModel.setDraggingFile(true)
        dragAndDropPreviewViewModel.setTargetedDropTarget(target)
        try await playLivePreview(
            makeDragAndDropTargetContent(for: target),
            id: id,
            duration: 3
        )
        dragAndDropPreviewViewModel.setDraggingFile(false)
    }

    private func playCombinedDragAndDropPreview() async throws {
        dragAndDropPreviewViewModel.setDraggingFile(true)
        dragAndDropPreviewViewModel.setTargetedDropTarget(.fileConverter)
        try await playLivePreview(
            DragAndDropCombinedNotchContent(
                airDropViewModel: dragAndDropPreviewViewModel,
                settingsViewModel: settingsViewModel
            ),
            id: Self.sequenceCombinedDropID,
            duration: 3
        )
        dragAndDropPreviewViewModel.setDraggingFile(false)
    }

    private func playFileTrayActivePreview() async throws {
        try prepareFileTrayPreviewItems()
        try await playLivePreview(
            TrayActiveNotchContent(
                fileTrayViewModel: fileTrayPreviewViewModel,
                mediaSettings: settingsViewModel.mediaAndFiles
            ),
            id: Self.sequenceTrayActiveID
        )
        fileTrayPreviewViewModel.clear()
    }

    private func playFileConverterActivePreview() async throws {
        try prepareFileConverterPreviewItem()
        try await playLivePreview(
            makeFileConverterActivePreviewContent(),
            id: Self.sequenceFileConverterActiveID
        )
        fileConverterPreviewViewModel.clear()
    }

    private func playFileConverterConvertingPreview() async throws {
        try prepareFileConverterPreviewItem()
        fileConverterPreviewViewModel.showDebugConvertingStatus()
        try await playLivePreview(
            makeFileConverterActivePreviewContent(),
            id: Self.sequenceFileConverterActiveID,
            duration: 3
        )
        fileConverterPreviewViewModel.clear()
    }

    private func playFileConverterFailedPreview() async throws {
        try prepareFileConverterPreviewItem()
        fileConverterPreviewViewModel.showDebugFailedStatus()
        try await playLivePreview(
            makeFileConverterActivePreviewContent(),
            id: Self.sequenceFileConverterActiveID,
            duration: 3
        )
        fileConverterPreviewViewModel.clear()
    }

    private func playFileConverterConvertedPreview() async throws {
        try prepareFileConverterPreviewItem()
        fileConverterPreviewViewModel.convert(options: fileConverterDebugConversionOptions)
        try await playLivePreview(
            makeFileConverterActivePreviewContent(),
            id: Self.sequenceFileConverterActiveID,
            duration: 3
        )
        fileConverterPreviewViewModel.clear()
    }

    private func playLockScreenPreview() async throws {
        lockScreenManager.setDebugLockState(true)
        try await playLivePreview(
            LockScreenNotchContent(
                lockScreenManager: lockScreenManager,
                style: settingsViewModel.lockScreen.lockScreenStyle
            ),
            id: Self.sequenceLockScreenID
        )
        lockScreenManager.setDebugLockState(false)
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

        dragAndDropPreviewViewModel.setDraggingFile(false)
        fileTrayPreviewViewModel.clear()
        fileConverterPreviewViewModel.clear()
        nowPlayingViewModel.hideDebugPreviewSnapshotIfNeeded()
        downloadViewModel.hideDebugPreviewDownloadsIfNeeded()
        timerViewModel.hideDebugPreviewSnapshotIfNeeded()
        lockScreenManager.setDebugLockState(isLockScreenPreviewEnabled)

        if isNowPlayingPreviewEnabled {
            updateNowPlayingPreview()
        }

        if isDownloadPreviewEnabled {
            updateDownloadPreview()
        }

        if isTimerPreviewEnabled {
            updateTimerPreview()
        }

        if isFileTrayPreviewEnabled {
            updateFileTrayPreview()
        }

        if isFileConverterPreviewEnabled {
            updateFileConverterPreview()
        }

        if isScreenRecordingPreviewEnabled {
            updateScreenRecordingPreview()
        }

        if isLockScreenPreviewEnabled {
            updateLockScreenPreview()
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

    private func prepareFileTrayPreviewItems() throws {
        fileTrayPreviewViewModel.clear()
        let directory = try debugPreviewDirectory()
        let reportURL = directory.appendingPathComponent("Debug Report.txt")
        let imageURL = directory.appendingPathComponent("Debug Image.png")

        try Data("DynamicNotch debug tray preview".utf8).write(to: reportURL, options: .atomic)
        try debugPNGData().write(to: imageURL, options: .atomic)
        fileTrayPreviewViewModel.add([reportURL, imageURL])
    }

    private func prepareFileConverterPreviewItem() throws {
        let imageURL = try debugPreviewDirectory().appendingPathComponent("Converter Preview.png")
        try debugPNGData().write(to: imageURL, options: .atomic)
        try fileConverterPreviewViewModel.setFile(imageURL)
    }

    private func debugPreviewDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DynamicNotch", isDirectory: true)
            .appendingPathComponent("DebugPreviews", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private func debugPNGData() throws -> Data {
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="

        guard let data = Data(base64Encoded: base64) else {
            throw NSError(
                domain: "DynamicNotch.DebugPreview",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not create the debug preview image."]
            )
        }

        return data
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
