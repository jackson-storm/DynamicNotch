import Combine
import Foundation
import ServiceManagement

enum NotchDisplayLocation: String, CaseIterable {
    case main
    case builtIn

    var title: String {
        switch self {
        case .main:
            return "Show on main display"
        case .builtIn:
            return "Show on built-in display"
        }
    }

    var symbolName: String {
        switch self {
        case .main:
            return "macbook.gen2"
        case .builtIn:
            return "desktopcomputer.and.macbook"
        }
    }
}

@MainActor
final class GeneralSettingsViewModel: ObservableObject, NotchSettingsProviding {
    enum ResetGroup {
        case general
        case nowPlaying
        case downloads
        case airDrop
        case focus
        case bluetooth
        case network
        case battery
        case hud
        case lockScreen
    }

    enum LiveActivityPreference {
        case hotspot
        case focus
        case nowPlaying
        case lockScreen
        case downloads
        case airDrop
    }

    enum TemporaryActivityPreference {
        case charger
        case lowPower
        case fullPower
        case bluetooth
        case wifi
        case vpn
        case focusOff
        case notchSize
    }

    enum HUDPreference {
        case brightness
        case keyboard
        case volume
    }

    @Published var isLaunchAtLoginEnabled: Bool {
        didSet {
            persist(isLaunchAtLoginEnabled, for: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var notchWidth: Int {
        didSet {
            guard oldValue != notchWidth else { return }
            persist(notchWidth, for: Keys.notchWidth)
            notchSizeEvent.send(.width)
        }
    }

    @Published var notchHeight: Int {
        didSet {
            guard oldValue != notchHeight else { return }
            persist(notchHeight, for: Keys.notchHeight)
            notchSizeEvent.send(.height)
        }
    }

    @Published var isMenuBarIconVisible: Bool {
        didSet {
            persist(isMenuBarIconVisible, for: Keys.menuBarIcon)
        }
    }

    @Published var isShowNotchStrokeEnabled: Bool {
        didSet {
            persist(isShowNotchStrokeEnabled, for: Keys.notchStrokeEnabled)
        }
    }

    @Published var notchStrokeWidth: Double {
        didSet {
            persist(notchStrokeWidth, for: Keys.notchStrokeWidth)
        }
    }

    @Published var displayLocation: NotchDisplayLocation {
        didSet {
            persist(displayLocation.rawValue, for: Keys.displayLocation)
        }
    }

    @Published var notchAnimationPreset: NotchAnimationPreset {
        didSet {
            persist(notchAnimationPreset.rawValue, for: Keys.notchAnimationPreset)
        }
    }

    @Published var isBrightnessHUDEnabled: Bool {
        didSet {
            persist(isBrightnessHUDEnabled, for: Keys.brightnessHUDEnabled)
        }
    }

    @Published var isKeyboardHUDEnabled: Bool {
        didSet {
            persist(isKeyboardHUDEnabled, for: Keys.keyboardHUDEnabled)
        }
    }

    @Published var isVolumeHUDEnabled: Bool {
        didSet {
            persist(isVolumeHUDEnabled, for: Keys.volumeHUDEnabled)
        }
    }

    @Published var isHotspotLiveActivityEnabled: Bool {
        didSet {
            persist(isHotspotLiveActivityEnabled, for: Keys.hotspotLiveActivityEnabled)
        }
    }

    @Published var isFocusLiveActivityEnabled: Bool {
        didSet {
            persist(isFocusLiveActivityEnabled, for: Keys.focusLiveActivityEnabled)
        }
    }

    @Published var isNowPlayingLiveActivityEnabled: Bool {
        didSet {
            persist(isNowPlayingLiveActivityEnabled, for: Keys.nowPlayingLiveActivityEnabled)
        }
    }

    @Published var isLockScreenLiveActivityEnabled: Bool {
        didSet {
            persist(isLockScreenLiveActivityEnabled, for: LockScreenSettings.liveActivityKey)
        }
    }
    
    @Published var isLockScreenSoundEnabled: Bool {
        didSet {
            persist(isLockScreenSoundEnabled, for: LockScreenSettings.soundKey)
        }
    }

    @Published var isLockScreenMediaPanelEnabled: Bool {
        didSet {
            persist(isLockScreenMediaPanelEnabled, for: LockScreenSettings.mediaPanelKey)
        }
    }

    @Published var isDownloadsLiveActivityEnabled: Bool {
        didSet {
            persist(isDownloadsLiveActivityEnabled, for: Keys.downloadsLiveActivityEnabled)
        }
    }

    @Published var isDownloadsDefaultStrokeEnabled: Bool {
        didSet {
            persist(isDownloadsDefaultStrokeEnabled, for: Keys.downloadsDefaultStrokeEnabled)
        }
    }

    @Published var isAirDropLiveActivityEnabled: Bool {
        didSet {
            persist(isAirDropLiveActivityEnabled, for: Keys.airDropLiveActivityEnabled)
        }
    }

    @Published var isAirDropDefaultStrokeEnabled: Bool {
        didSet {
            persist(isAirDropDefaultStrokeEnabled, for: Keys.airDropDefaultStrokeEnabled)
        }
    }

    @Published var isChargerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isChargerTemporaryActivityEnabled, for: Keys.chargerTemporaryActivityEnabled)
        }
    }

    @Published var isLowPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isLowPowerTemporaryActivityEnabled, for: Keys.lowPowerTemporaryActivityEnabled)
        }
    }

    @Published var isFullPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFullPowerTemporaryActivityEnabled, for: Keys.fullPowerTemporaryActivityEnabled)
        }
    }

    @Published var isBluetoothTemporaryActivityEnabled: Bool {
        didSet {
            persist(isBluetoothTemporaryActivityEnabled, for: Keys.bluetoothTemporaryActivityEnabled)
        }
    }

    @Published var isWifiTemporaryActivityEnabled: Bool {
        didSet {
            persist(isWifiTemporaryActivityEnabled, for: Keys.wifiTemporaryActivityEnabled)
        }
    }

    @Published var isVpnTemporaryActivityEnabled: Bool {
        didSet {
            persist(isVpnTemporaryActivityEnabled, for: Keys.vpnTemporaryActivityEnabled)
        }
    }

    @Published var isFocusOffTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFocusOffTemporaryActivityEnabled, for: Keys.focusOffTemporaryActivityEnabled)
        }
    }

    @Published var isFocusDefaultStrokeEnabled: Bool {
        didSet {
            persist(isFocusDefaultStrokeEnabled, for: Keys.focusDefaultStrokeEnabled)
        }
    }

    @Published var isNotchSizeTemporaryActivityEnabled: Bool {
        didSet {
            persist(isNotchSizeTemporaryActivityEnabled, for: Keys.notchSizeTemporaryActivityEnabled)
        }
    }

    @Published var isHotspotDefaultStrokeEnabled: Bool {
        didSet {
            persist(isHotspotDefaultStrokeEnabled, for: Keys.hotspotDefaultStrokeEnabled)
        }
    }

    @Published var isBatteryDefaultStrokeEnabled: Bool {
        didSet {
            persist(isBatteryDefaultStrokeEnabled, for: Keys.batteryDefaultStrokeEnabled)
        }
    }

    let notchSizeEvent = PassthroughSubject<NotchSizeEvent, Never>()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: Self.defaultValues)

        self.isLaunchAtLoginEnabled = defaults.bool(forKey: Keys.launchAtLogin)
        self.notchWidth = defaults.integer(forKey: Keys.notchWidth)
        self.notchHeight = defaults.integer(forKey: Keys.notchHeight)
        self.isMenuBarIconVisible = defaults.bool(forKey: Keys.menuBarIcon)
        self.isShowNotchStrokeEnabled = defaults.bool(forKey: Keys.notchStrokeEnabled)
        self.notchStrokeWidth = defaults.double(forKey: Keys.notchStrokeWidth)
        self.displayLocation = NotchDisplayLocation(rawValue: defaults.string(forKey: Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue) ?? .main
        self.notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaults.string(forKey: Keys.notchAnimationPreset) ?? NotchAnimationPreset.balanced.rawValue
        ) ?? .balanced
        self.isBrightnessHUDEnabled = defaults.bool(forKey: Keys.brightnessHUDEnabled)
        self.isKeyboardHUDEnabled = defaults.bool(forKey: Keys.keyboardHUDEnabled)
        self.isVolumeHUDEnabled = defaults.bool(forKey: Keys.volumeHUDEnabled)
        self.isHotspotLiveActivityEnabled = defaults.bool(forKey: Keys.hotspotLiveActivityEnabled)
        self.isFocusLiveActivityEnabled = defaults.bool(forKey: Keys.focusLiveActivityEnabled)
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: Keys.nowPlayingLiveActivityEnabled)
        self.isLockScreenLiveActivityEnabled = defaults.bool(forKey: LockScreenSettings.liveActivityKey)
        self.isLockScreenSoundEnabled = defaults.bool(forKey: LockScreenSettings.soundKey)
        self.isLockScreenMediaPanelEnabled = defaults.bool(forKey: LockScreenSettings.mediaPanelKey)
        let hasLegacyDownloadsValue = defaults.object(forKey: Keys.legacyFileTransfersLiveActivityEnabled) != nil
        let downloadsSettingValue = defaults.object(forKey: Keys.downloadsLiveActivityEnabled) as? Bool
        self.isDownloadsLiveActivityEnabled = downloadsSettingValue ?? (
            hasLegacyDownloadsValue ?
            defaults.bool(forKey: Keys.legacyFileTransfersLiveActivityEnabled) :
            (Self.defaultValues[Keys.downloadsLiveActivityEnabled] as? Bool ?? true)
        )
        self.isDownloadsDefaultStrokeEnabled = defaults.bool(forKey: Keys.downloadsDefaultStrokeEnabled)
        self.isAirDropLiveActivityEnabled = defaults.bool(forKey: Keys.airDropLiveActivityEnabled)
        self.isAirDropDefaultStrokeEnabled = defaults.bool(forKey: Keys.airDropDefaultStrokeEnabled)
        self.isChargerTemporaryActivityEnabled = defaults.bool(forKey: Keys.chargerTemporaryActivityEnabled)
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: Keys.lowPowerTemporaryActivityEnabled)
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: Keys.fullPowerTemporaryActivityEnabled)
        self.isBluetoothTemporaryActivityEnabled = defaults.bool(forKey: Keys.bluetoothTemporaryActivityEnabled)
        self.isWifiTemporaryActivityEnabled = defaults.bool(forKey: Keys.wifiTemporaryActivityEnabled)
        self.isVpnTemporaryActivityEnabled = defaults.bool(forKey: Keys.vpnTemporaryActivityEnabled)
        self.isFocusOffTemporaryActivityEnabled = defaults.bool(forKey: Keys.focusOffTemporaryActivityEnabled)
        self.isNotchSizeTemporaryActivityEnabled = defaults.bool(forKey: Keys.notchSizeTemporaryActivityEnabled)
        self.isFocusDefaultStrokeEnabled = defaults.bool(forKey: Keys.focusDefaultStrokeEnabled)
        self.isHotspotDefaultStrokeEnabled = defaults.bool(forKey: Keys.hotspotDefaultStrokeEnabled)
        self.isBatteryDefaultStrokeEnabled = defaults.bool(forKey: Keys.batteryDefaultStrokeEnabled)

        updateLaunchAtLogin()
    }

    func isLiveActivityEnabled(_ preference: LiveActivityPreference) -> Bool {
        switch preference {
        case .hotspot:
            return isHotspotLiveActivityEnabled
        case .focus:
            return isFocusLiveActivityEnabled
        case .nowPlaying:
            return isNowPlayingLiveActivityEnabled
        case .lockScreen:
            return isLockScreenLiveActivityEnabled
        case .downloads:
            return isDownloadsLiveActivityEnabled
        case .airDrop:
            return isAirDropLiveActivityEnabled
        }
    }

    func isHUDEnabled(_ preference: HUDPreference) -> Bool {
        switch preference {
        case .brightness:
            return isBrightnessHUDEnabled
        case .keyboard:
            return isKeyboardHUDEnabled
        case .volume:
            return isVolumeHUDEnabled
        }
    }

    func isTemporaryActivityEnabled(_ preference: TemporaryActivityPreference) -> Bool {
        switch preference {
        case .charger:
            return isChargerTemporaryActivityEnabled
        case .lowPower:
            return isLowPowerTemporaryActivityEnabled
        case .fullPower:
            return isFullPowerTemporaryActivityEnabled
        case .bluetooth:
            return isBluetoothTemporaryActivityEnabled
        case .wifi:
            return isWifiTemporaryActivityEnabled
        case .vpn:
            return isVpnTemporaryActivityEnabled
        case .focusOff:
            return isFocusOffTemporaryActivityEnabled
        case .notchSize:
            return isNotchSizeTemporaryActivityEnabled
        }
    }

    func reset(_ group: ResetGroup) {
        switch group {
        case .general:
            isLaunchAtLoginEnabled = defaultBool(for: Keys.launchAtLogin)
            isMenuBarIconVisible = defaultBool(for: Keys.menuBarIcon)
            displayLocation = NotchDisplayLocation(
                rawValue: defaultString(for: Keys.displayLocation)
            ) ?? .main
            notchAnimationPreset = NotchAnimationPreset(
                rawValue: defaultString(for: Keys.notchAnimationPreset)
            ) ?? .balanced
            isShowNotchStrokeEnabled = defaultBool(for: Keys.notchStrokeEnabled)
            isNotchSizeTemporaryActivityEnabled = defaultBool(for: Keys.notchSizeTemporaryActivityEnabled)
            notchStrokeWidth = defaultDouble(for: Keys.notchStrokeWidth)
            notchWidth = defaultInt(for: Keys.notchWidth)
            notchHeight = defaultInt(for: Keys.notchHeight)

        case .nowPlaying:
            isNowPlayingLiveActivityEnabled = defaultBool(for: Keys.nowPlayingLiveActivityEnabled)

        case .downloads:
            isDownloadsLiveActivityEnabled = defaultBool(for: Keys.downloadsLiveActivityEnabled)
            isDownloadsDefaultStrokeEnabled = defaultBool(for: Keys.downloadsDefaultStrokeEnabled)

        case .airDrop:
            isAirDropLiveActivityEnabled = defaultBool(for: Keys.airDropLiveActivityEnabled)
            isAirDropDefaultStrokeEnabled = defaultBool(for: Keys.airDropDefaultStrokeEnabled)

        case .focus:
            isFocusLiveActivityEnabled = defaultBool(for: Keys.focusLiveActivityEnabled)
            isFocusOffTemporaryActivityEnabled = defaultBool(for: Keys.focusOffTemporaryActivityEnabled)
            isFocusDefaultStrokeEnabled = defaultBool(for: Keys.focusDefaultStrokeEnabled)

        case .bluetooth:
            isBluetoothTemporaryActivityEnabled = defaultBool(for: Keys.bluetoothTemporaryActivityEnabled)

        case .network:
            isHotspotLiveActivityEnabled = defaultBool(for: Keys.hotspotLiveActivityEnabled)
            isWifiTemporaryActivityEnabled = defaultBool(for: Keys.wifiTemporaryActivityEnabled)
            isVpnTemporaryActivityEnabled = defaultBool(for: Keys.vpnTemporaryActivityEnabled)
            isHotspotDefaultStrokeEnabled = defaultBool(for: Keys.hotspotDefaultStrokeEnabled)

        case .battery:
            isChargerTemporaryActivityEnabled = defaultBool(for: Keys.chargerTemporaryActivityEnabled)
            isLowPowerTemporaryActivityEnabled = defaultBool(for: Keys.lowPowerTemporaryActivityEnabled)
            isFullPowerTemporaryActivityEnabled = defaultBool(for: Keys.fullPowerTemporaryActivityEnabled)
            isBatteryDefaultStrokeEnabled = defaultBool(for: Keys.batteryDefaultStrokeEnabled)

        case .hud:
            isBrightnessHUDEnabled = defaultBool(for: Keys.brightnessHUDEnabled)
            isKeyboardHUDEnabled = defaultBool(for: Keys.keyboardHUDEnabled)
            isVolumeHUDEnabled = defaultBool(for: Keys.volumeHUDEnabled)

        case .lockScreen:
            isLockScreenLiveActivityEnabled = defaultBool(for: LockScreenSettings.liveActivityKey)
            isLockScreenSoundEnabled = defaultBool(for: LockScreenSettings.soundKey)
            isLockScreenMediaPanelEnabled = defaultBool(for: LockScreenSettings.mediaPanelKey)
        }
    }

    private func persist(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func persist(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func persist(_ value: Double, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func persist(_ value: String, for key: String) {
        defaults.set(value, forKey: key)
    }

    private func defaultBool(for key: String) -> Bool {
        (Self.defaultValues[key] as? Bool) ?? false
    }

    private func defaultInt(for key: String) -> Int {
        (Self.defaultValues[key] as? Int) ?? 0
    }

    private func defaultDouble(for key: String) -> Double {
        (Self.defaultValues[key] as? Double) ?? 0
    }

    private func defaultString(for key: String) -> String {
        (Self.defaultValues[key] as? String) ?? ""
    }

    private func updateLaunchAtLogin() {
        let instance = SMAppService.mainApp

        do {
            if isLaunchAtLoginEnabled {
                try instance.register()
            } else {
                try instance.unregister()
            }
        } catch {
            print("Ошибка для \(instance.description): \(error)")
        }
    }
}

private extension GeneralSettingsViewModel {
    enum Keys {
        static let launchAtLogin = "isLaunchAtLoginEnabled"
        static let notchWidth = "notchWidth"
        static let notchHeight = "notchHeight"
        static let menuBarIcon = "isMenuBarIconVisible"
        static let notchStrokeEnabled = "isShowNotchStrokeEnabled"
        static let notchStrokeWidth = "notchStrokeWidth"
        static let displayLocation = "displayLocation"
        static let notchAnimationPreset = "settings.general.notchAnimationPreset"
        static let brightnessHUDEnabled = "settings.hud.brightness"
        static let keyboardHUDEnabled = "settings.hud.keyboard"
        static let volumeHUDEnabled = "settings.hud.volume"
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
        Keys.notchWidth: 0,
        Keys.notchHeight: 0,
        Keys.menuBarIcon: true,
        Keys.notchStrokeEnabled: true,
        Keys.notchStrokeWidth: 1.5,
        Keys.displayLocation: NotchDisplayLocation.main.rawValue,
        Keys.notchAnimationPreset: NotchAnimationPreset.balanced.rawValue,
        Keys.brightnessHUDEnabled: true,
        Keys.keyboardHUDEnabled: true,
        Keys.volumeHUDEnabled: true,
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
