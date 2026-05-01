enum GeneralSettingsStorage {
    enum Keys {
        static let launchAtLogin = "isLaunchAtLoginEnabled"
        static let dockIcon = "isDockIconVisible"
        static let appearanceMode = "settings.general.appearance.mode"
        static let notchBackgroundStyle = "settings.notch.backgroundStyle"
        static let notchWidth = "notchWidth"
        static let notchHeight = "notchHeight"
        static let menuBarIcon = "isMenuBarIconVisible"
        static let notchStrokeEnabled = "isShowNotchStrokeEnabled"
        static let defaultActivityStrokeEnabled = "settings.general.defaultActivityStroke"
        static let notchStrokeWidth = "notchStrokeWidth"
        static let displayLocation = "displayLocation"
        static let preferredDisplayUUID = "settings.general.display.preferred.uuid"
        static let preferredDisplayName = "settings.general.display.preferred.name"
        static let displayAutoSwitchEnabled = "settings.general.display.autoSwitchEnabled"
        static let appLanguage = "settings.general.language.app"
        static let notchAnimationPreset = "settings.general.notchAnimationPreset"
        static let hideNotchInFullscreenEnabled = "settings.general.hideNotchInFullscreen"
        static let notchTapToExpandEnabled = "settings.notch.gestures.tapToExpand"
        static let notchExpandInteraction = "settings.notch.gestures.expandInteraction"
        static let notchPressHoldDuration = "settings.notch.gestures.pressHoldDuration"
        static let notchMouseDragGesturesEnabled = "settings.notch.gestures.mouseDrag"
        static let notchTrackpadSwipeGesturesEnabled = "settings.notch.gestures.trackpadSwipe"
        static let notchSwipeDismissEnabled = "settings.notch.gestures.dismiss"
        static let notchSwipeRestoreEnabled = "settings.notch.gestures.restore"
        static let notchContentPriorityOverrides = NotchContentPriority.overrideStorageKey
        static let brightnessHUDEnabled = "settings.hud.brightness"
        static let keyboardHUDEnabled = "settings.hud.keyboard"
        static let volumeHUDEnabled = "settings.hud.volume"
        static let brightnessHUDDuration = "settings.hud.brightness.duration"
        static let keyboardHUDDuration = "settings.hud.keyboard.duration"
        static let volumeHUDDuration = "settings.hud.volume.duration"
        static let hudStyle = "settings.hud.style"
        static let hudIndicatorStyle = "settings.hud.indicatorStyle"
        static let hudColoredLevelEnabled = "settings.hud.coloredLevel"
        static let hudColoredStrokeEnabled = "settings.hud.coloredStroke"
        static let hotspotLiveActivityEnabled = "settings.live.hotspot"
        static let focusLiveActivityEnabled = "settings.live.focus"
        static let focusAppearanceStyle = "settings.focus.appearanceStyle"
        static let nowPlayingLiveActivityEnabled = "settings.live.nowPlaying"
        static let nowPlayingFavoriteButtonVisible = "settings.nowPlaying.favoriteButtonVisible"
        static let nowPlayingOutputDeviceButtonVisible = "settings.nowPlaying.outputDeviceButtonVisible"
        static let nowPlayingArtworkTintEnabled = "settings.nowPlaying.artworkTintEnabled"
        static let nowPlayingArtworkStrokeEnabled = "settings.nowPlaying.artworkStrokeEnabled"
        static let nowPlayingEqualizerMode = "settings.nowPlaying.equalizerMode"
        static let nowPlayingPauseHideTimerEnabled = "settings.nowPlaying.pauseHideTimerEnabled"
        static let nowPlayingPauseHideDelay = "settings.nowPlaying.pauseHideDelay"
        static let downloadsLiveActivityEnabled = "settings.live.downloads"
        static let downloadsDefaultStrokeEnabled = "settings.live.downloads.defaultStroke"
        static let downloadsAppearanceStyle = "settings.live.downloads.appearanceStyle"
        static let downloadsProgressIndicatorStyle = "settings.live.downloads.progressIndicatorStyle"
        static let airDropLiveActivityEnabled = "settings.live.airDrop"
        static let airDropDefaultStrokeEnabled = "settings.live.airDrop.defaultStroke"
        static let dragAndDropActivityMode = "settings.live.dragAndDrop.mode"
        static let dropMotionAnimationEnabled = "settings.live.drop.motionAnimation"
        static let trayLiveActivityEnabled = "settings.live.tray"
        static let timerLiveActivityEnabled = "settings.live.timer"
        static let timerDefaultStrokeEnabled = "settings.live.timer.defaultStroke"
        static let screenRecordingLiveActivityEnabled = "settings.live.screenRecording"
        static let screenRecordingDefaultStrokeEnabled = "settings.live.screenRecording.defaultStroke"
        static let legacyFileTransfersLiveActivityEnabled = "settings.live.fileTransfers"
        static let chargerTemporaryActivityEnabled = "settings.temporary.charger"
        static let lowPowerTemporaryActivityEnabled = "settings.temporary.lowPower"
        static let fullPowerTemporaryActivityEnabled = "settings.temporary.fullPower"
        static let temporaryActivityDurationScale = "settings.temporary.durationScale"
        static let chargerTemporaryActivityDuration = "settings.temporary.charger.duration"
        static let lowPowerTemporaryActivityDuration = "settings.temporary.lowPower.duration"
        static let fullPowerTemporaryActivityDuration = "settings.temporary.fullPower.duration"
        static let lowPowerNotificationThreshold = "settings.temporary.lowPower.threshold"
        static let fullPowerNotificationThreshold = "settings.temporary.fullPower.threshold"
        static let lowPowerNotificationStyle = "settings.temporary.lowPower.style"
        static let fullPowerNotificationStyle = "settings.temporary.fullPower.style"
        static let bluetoothTemporaryActivityEnabled = "settings.temporary.bluetooth"
        static let bluetoothTemporaryActivityDuration = "settings.temporary.bluetooth.duration"
        static let bluetoothAppearanceStyle = "settings.bluetooth.appearanceStyle"
        static let bluetoothBatteryStrokeEnabled = "settings.bluetooth.batteryStrokeEnabled"
        static let bluetoothBatteryIndicatorStyle = "settings.bluetooth.batteryIndicatorStyle"
        static let wifiTemporaryActivityEnabled = "settings.temporary.wifi"
        static let wifiTemporaryActivityDuration = "settings.temporary.wifi.duration"
        static let vpnTemporaryActivityEnabled = "settings.temporary.vpn"
        static let vpnTemporaryActivityDuration = "settings.temporary.vpn.duration"
        static let noInternetTemporaryActivityEnabled = "settings.temporary.noInternet"
        static let hotspotAppearanceStyle = "settings.network.hotspotAppearanceStyle"
        static let networkShowVPNDetail = "settings.network.showVPNDetail"
        static let networkShowVPNTimer = "settings.network.showVPNTimer"
        static let networkOnlyNotifyOnChange = "settings.network.onlyNotifyOnChange"
        static let focusOffTemporaryActivityEnabled = "settings.temporary.focusOff"
        static let focusOffTemporaryActivityDuration = "settings.temporary.focusOff.duration"
        static let notchSizeTemporaryActivityEnabled = "settings.temporary.notchSize"
        static let notchSizeTemporaryActivityDuration = "settings.temporary.notchSize.duration"
        static let focusDefaultStrokeEnabled = "settings.focus.defaultStroke"
        static let hotspotDefaultStrokeEnabled = "settings.live.hotspot.defaultStroke"
        static let lowPowerDefaultStrokeEnabled = "settings.battery.lowPower.defaultStroke"
        static let fullPowerDefaultStrokeEnabled = "settings.battery.fullPower.defaultStroke"
    }

    static let defaultValues: [String: Any] = [
        Keys.launchAtLogin: true,
        Keys.dockIcon: false,
        Keys.appearanceMode: SettingsAppearanceMode.system.rawValue,
        Keys.notchBackgroundStyle: NotchBackgroundStyle.black.rawValue,
        Keys.notchWidth: 0,
        Keys.notchHeight: 0,
        Keys.menuBarIcon: true,
        Keys.notchStrokeEnabled: true,
        Keys.defaultActivityStrokeEnabled: false,
        Keys.notchStrokeWidth: 1.5,
        Keys.displayLocation: NotchDisplayLocation.main.rawValue,
        Keys.preferredDisplayUUID: "",
        Keys.preferredDisplayName: "",
        Keys.displayAutoSwitchEnabled: true,
        Keys.appLanguage: DynamicNotchLanguage.system.rawValue,
        Keys.notchAnimationPreset: NotchAnimationPreset.balanced.rawValue,
        Keys.hideNotchInFullscreenEnabled: false,
        Keys.notchTapToExpandEnabled: true,
        Keys.notchExpandInteraction: NotchExpandInteraction.pressAndHold.rawValue,
        Keys.notchPressHoldDuration: 0.25,
        Keys.notchMouseDragGesturesEnabled: true,
        Keys.notchTrackpadSwipeGesturesEnabled: true,
        Keys.notchSwipeDismissEnabled: true,
        Keys.notchSwipeRestoreEnabled: true,
        Keys.notchContentPriorityOverrides: [:],
        Keys.brightnessHUDEnabled: true,
        Keys.keyboardHUDEnabled: true,
        Keys.volumeHUDEnabled: true,
        Keys.brightnessHUDDuration: 2,
        Keys.keyboardHUDDuration: 2,
        Keys.volumeHUDDuration: 2,
        Keys.hudStyle: HudStyle.compact.rawValue,
        Keys.hudIndicatorStyle: HudIndicatorStyle.bar.rawValue,
        Keys.hudColoredLevelEnabled: true,
        Keys.hudColoredStrokeEnabled: false,
        Keys.hotspotLiveActivityEnabled: true,
        Keys.focusLiveActivityEnabled: true,
        Keys.focusAppearanceStyle: FocusAppearanceStyle.iconsOnly.rawValue,
        Keys.nowPlayingLiveActivityEnabled: true,
        Keys.nowPlayingFavoriteButtonVisible: true,
        Keys.nowPlayingOutputDeviceButtonVisible: true,
        Keys.nowPlayingArtworkTintEnabled: false,
        Keys.nowPlayingArtworkStrokeEnabled: false,
        Keys.nowPlayingEqualizerMode: NowPlayingEqualizerMode.classic.rawValue,
        Keys.nowPlayingPauseHideTimerEnabled: true,
        Keys.nowPlayingPauseHideDelay: 5,
        Keys.downloadsLiveActivityEnabled: true,
        Keys.downloadsDefaultStrokeEnabled: false,
        Keys.downloadsAppearanceStyle: DownloadAppearanceStyle.minimal.rawValue,
        Keys.downloadsProgressIndicatorStyle: DownloadProgressIndicatorStyle.percent.rawValue,
        Keys.airDropLiveActivityEnabled: true,
        Keys.airDropDefaultStrokeEnabled: false,
        Keys.dragAndDropActivityMode: DragAndDropActivityMode.combined.rawValue,
        Keys.dropMotionAnimationEnabled: true,
        Keys.trayLiveActivityEnabled: true,
        Keys.timerLiveActivityEnabled: true,
        Keys.timerDefaultStrokeEnabled: false,
        Keys.screenRecordingLiveActivityEnabled: true,
        Keys.screenRecordingDefaultStrokeEnabled: false,
        LockScreenSettings.liveActivityKey: true,
        LockScreenSettings.soundKey: true,
        LockScreenSettings.customSoundPathKey: "",
        LockScreenSettings.customLockSoundPathKey: "",
        LockScreenSettings.customUnlockSoundPathKey: "",
        LockScreenSettings.mediaPanelKey: true,
        LockScreenSettings.styleKey: LockScreenStyle.compact.rawValue,
        LockScreenSettings.widgetAppearanceStyleKey: LockScreenWidgetAppearanceStyle.ultraThinMaterial.rawValue,
        LockScreenSettings.widgetTintStyleKey: LockScreenWidgetTintStyle.neutral.rawValue,
        LockScreenSettings.widgetBackgroundBrightnessKey: 1.0,
        LockScreenSettings.mediaPanelBackgroundStyleKey: LockScreenMediaPanelBackgroundStyle.animatedArtwork.rawValue,
        Keys.chargerTemporaryActivityEnabled: true,
        Keys.temporaryActivityDurationScale: 1.0,
        Keys.chargerTemporaryActivityDuration: 4,
        Keys.lowPowerTemporaryActivityEnabled: true,
        Keys.lowPowerTemporaryActivityDuration: 4,
        Keys.fullPowerTemporaryActivityEnabled: true,
        Keys.fullPowerTemporaryActivityDuration: 4,
        Keys.lowPowerNotificationThreshold: 20,
        Keys.fullPowerNotificationThreshold: 100,
        Keys.lowPowerNotificationStyle: BatteryNotificationStyle.standard.rawValue,
        Keys.fullPowerNotificationStyle: BatteryNotificationStyle.standard.rawValue,
        Keys.bluetoothTemporaryActivityEnabled: true,
        Keys.bluetoothTemporaryActivityDuration: 5,
        Keys.bluetoothAppearanceStyle: BluetoothAppearanceStyle.device.rawValue,
        Keys.bluetoothBatteryStrokeEnabled: false,
        Keys.bluetoothBatteryIndicatorStyle: BluetoothBatteryIndicatorStyle.percent.rawValue,
        Keys.wifiTemporaryActivityEnabled: true,
        Keys.wifiTemporaryActivityDuration: 3,
        Keys.vpnTemporaryActivityEnabled: true,
        Keys.vpnTemporaryActivityDuration: 5,
        Keys.noInternetTemporaryActivityEnabled: true,
        Keys.hotspotAppearanceStyle: HotspotAppearanceStyle.minimal.rawValue,
        Keys.networkShowVPNDetail: false,
        Keys.networkShowVPNTimer: true,
        Keys.networkOnlyNotifyOnChange: false,
        Keys.focusOffTemporaryActivityEnabled: true,
        Keys.focusOffTemporaryActivityDuration: 3,
        Keys.notchSizeTemporaryActivityEnabled: true,
        Keys.notchSizeTemporaryActivityDuration: 2,
        Keys.focusDefaultStrokeEnabled: false,
        Keys.hotspotDefaultStrokeEnabled: false,
        Keys.lowPowerDefaultStrokeEnabled: false,
        Keys.fullPowerDefaultStrokeEnabled: false
    ]
}
