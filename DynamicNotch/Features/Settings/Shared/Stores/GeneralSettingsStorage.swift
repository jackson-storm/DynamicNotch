enum GeneralSettingsStorage {
    enum Keys {
        static let launchAtLogin = "isLaunchAtLoginEnabled"
        static let dockIcon = "isDockIconVisible"
        static let appearanceMode = "settings.general.appearance.mode"
        static let appTint = "settings.general.appearance.tint"
        static let notchWidth = "notchWidth"
        static let notchHeight = "notchHeight"
        static let menuBarIcon = "isMenuBarIconVisible"
        static let notchStrokeEnabled = "isShowNotchStrokeEnabled"
        static let defaultActivityStrokeEnabled = "settings.general.defaultActivityStroke"
        static let notchStrokeWidth = "notchStrokeWidth"
        static let displayLocation = "displayLocation"
        static let appLanguage = "settings.general.language.app"
        static let notchAnimationPreset = "settings.general.notchAnimationPreset"
        static let temporaryActivityDurationScale = "settings.temporary.durationScale"
        static let brightnessHUDEnabled = "settings.hud.brightness"
        static let keyboardHUDEnabled = "settings.hud.keyboard"
        static let volumeHUDEnabled = "settings.hud.volume"
        static let hudStyle = "settings.hud.style"
        static let hudColoredLevelEnabled = "settings.hud.coloredLevel"
        static let hudColoredStrokeEnabled = "settings.hud.coloredStroke"
        static let hotspotLiveActivityEnabled = "settings.live.hotspot"
        static let focusLiveActivityEnabled = "settings.live.focus"
        static let nowPlayingLiveActivityEnabled = "settings.live.nowPlaying"
        static let downloadsLiveActivityEnabled = "settings.live.downloads"
        static let downloadsDefaultStrokeEnabled = "settings.live.downloads.defaultStroke"
        static let airDropLiveActivityEnabled = "settings.live.airDrop"
        static let airDropDefaultStrokeEnabled = "settings.live.airDrop.defaultStroke"
        static let legacyFileTransfersLiveActivityEnabled = "settings.live.fileTransfers"
        static let chargerTemporaryActivityEnabled = "settings.temporary.charger"
        static let lowPowerTemporaryActivityEnabled = "settings.temporary.lowPower"
        static let fullPowerTemporaryActivityEnabled = "settings.temporary.fullPower"
        static let bluetoothTemporaryActivityEnabled = "settings.temporary.bluetooth"
        static let wifiTemporaryActivityEnabled = "settings.temporary.wifi"
        static let vpnTemporaryActivityEnabled = "settings.temporary.vpn"
        static let focusOffTemporaryActivityEnabled = "settings.temporary.focusOff"
        static let notchSizeTemporaryActivityEnabled = "settings.temporary.notchSize"
        static let focusDefaultStrokeEnabled = "settings.focus.defaultStroke"
        static let hotspotDefaultStrokeEnabled = "settings.live.hotspot.defaultStroke"
        static let batteryDefaultStrokeEnabled = "settings.battery.defaultStroke"
    }

    static let defaultValues: [String: Any] = [
        Keys.launchAtLogin: true,
        Keys.dockIcon: false,
        Keys.appearanceMode: SettingsAppearanceMode.system.rawValue,
        Keys.appTint: AppTint.blue.rawValue,
        Keys.notchWidth: 0,
        Keys.notchHeight: 0,
        Keys.menuBarIcon: true,
        Keys.notchStrokeEnabled: true,
        Keys.defaultActivityStrokeEnabled: false,
        Keys.notchStrokeWidth: 1.5,
        Keys.displayLocation: NotchDisplayLocation.main.rawValue,
        Keys.appLanguage: DynamicNotchLanguage.system.rawValue,
        Keys.notchAnimationPreset: NotchAnimationPreset.balanced.rawValue,
        Keys.temporaryActivityDurationScale: 1.0,
        Keys.brightnessHUDEnabled: true,
        Keys.keyboardHUDEnabled: true,
        Keys.volumeHUDEnabled: true,
        Keys.hudStyle: HudStyle.standard.rawValue,
        Keys.hudColoredLevelEnabled: true,
        Keys.hudColoredStrokeEnabled: false,
        Keys.hotspotLiveActivityEnabled: true,
        Keys.focusLiveActivityEnabled: true,
        Keys.nowPlayingLiveActivityEnabled: true,
        Keys.downloadsLiveActivityEnabled: true,
        Keys.downloadsDefaultStrokeEnabled: false,
        Keys.airDropLiveActivityEnabled: true,
        Keys.airDropDefaultStrokeEnabled: false,
        LockScreenSettings.liveActivityKey: true,
        LockScreenSettings.soundKey: true,
        LockScreenSettings.mediaPanelKey: true,
        Keys.chargerTemporaryActivityEnabled: true,
        Keys.lowPowerTemporaryActivityEnabled: true,
        Keys.fullPowerTemporaryActivityEnabled: true,
        Keys.bluetoothTemporaryActivityEnabled: true,
        Keys.wifiTemporaryActivityEnabled: true,
        Keys.vpnTemporaryActivityEnabled: true,
        Keys.focusOffTemporaryActivityEnabled: true,
        Keys.notchSizeTemporaryActivityEnabled: true,
        Keys.focusDefaultStrokeEnabled: false,
        Keys.hotspotDefaultStrokeEnabled: false,
        Keys.batteryDefaultStrokeEnabled: false
    ]
}
