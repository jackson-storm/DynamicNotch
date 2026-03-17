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
    enum LiveActivityPreference {
        case airDrop
        case hotspot
        case focus
        case nowPlaying
        case lockScreen
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

    @Published var isAirDropLiveActivityEnabled: Bool {
        didSet {
            persist(isAirDropLiveActivityEnabled, for: Keys.airDropLiveActivityEnabled)
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

    @Published var isLockScreenMediaPanelEnabled: Bool {
        didSet {
            persist(isLockScreenMediaPanelEnabled, for: LockScreenSettings.mediaPanelKey)
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

    @Published var isNotchSizeTemporaryActivityEnabled: Bool {
        didSet {
            persist(isNotchSizeTemporaryActivityEnabled, for: Keys.notchSizeTemporaryActivityEnabled)
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
        self.displayLocation = NotchDisplayLocation(
            rawValue: defaults.string(forKey: Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue
        ) ?? .main
        self.isBrightnessHUDEnabled = defaults.bool(forKey: Keys.brightnessHUDEnabled)
        self.isKeyboardHUDEnabled = defaults.bool(forKey: Keys.keyboardHUDEnabled)
        self.isVolumeHUDEnabled = defaults.bool(forKey: Keys.volumeHUDEnabled)
        self.isAirDropLiveActivityEnabled = defaults.bool(forKey: Keys.airDropLiveActivityEnabled)
        self.isHotspotLiveActivityEnabled = defaults.bool(forKey: Keys.hotspotLiveActivityEnabled)
        self.isFocusLiveActivityEnabled = defaults.bool(forKey: Keys.focusLiveActivityEnabled)
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: Keys.nowPlayingLiveActivityEnabled)
        self.isLockScreenLiveActivityEnabled = defaults.bool(forKey: LockScreenSettings.liveActivityKey)
        self.isLockScreenMediaPanelEnabled = defaults.bool(forKey: LockScreenSettings.mediaPanelKey)
        self.isChargerTemporaryActivityEnabled = defaults.bool(forKey: Keys.chargerTemporaryActivityEnabled)
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: Keys.lowPowerTemporaryActivityEnabled)
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: Keys.fullPowerTemporaryActivityEnabled)
        self.isBluetoothTemporaryActivityEnabled = defaults.bool(forKey: Keys.bluetoothTemporaryActivityEnabled)
        self.isWifiTemporaryActivityEnabled = defaults.bool(forKey: Keys.wifiTemporaryActivityEnabled)
        self.isVpnTemporaryActivityEnabled = defaults.bool(forKey: Keys.vpnTemporaryActivityEnabled)
        self.isFocusOffTemporaryActivityEnabled = defaults.bool(forKey: Keys.focusOffTemporaryActivityEnabled)
        self.isNotchSizeTemporaryActivityEnabled = defaults.bool(forKey: Keys.notchSizeTemporaryActivityEnabled)

        updateLaunchAtLogin()
    }

    func isLiveActivityEnabled(_ preference: LiveActivityPreference) -> Bool {
        switch preference {
        case .airDrop:
            return isAirDropLiveActivityEnabled
        case .hotspot:
            return isHotspotLiveActivityEnabled
        case .focus:
            return isFocusLiveActivityEnabled
        case .nowPlaying:
            return isNowPlayingLiveActivityEnabled
        case .lockScreen:
            return isLockScreenLiveActivityEnabled
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
        static let brightnessHUDEnabled = "settings.hud.brightness"
        static let keyboardHUDEnabled = "settings.hud.keyboard"
        static let volumeHUDEnabled = "settings.hud.volume"
        static let airDropLiveActivityEnabled = "settings.live.airdrop"
        static let hotspotLiveActivityEnabled = "settings.live.hotspot"
        static let focusLiveActivityEnabled = "settings.live.focus"
        static let nowPlayingLiveActivityEnabled = "settings.live.nowPlaying"
        static let chargerTemporaryActivityEnabled = "settings.temporary.charger"
        static let lowPowerTemporaryActivityEnabled = "settings.temporary.lowPower"
        static let fullPowerTemporaryActivityEnabled = "settings.temporary.fullPower"
        static let bluetoothTemporaryActivityEnabled = "settings.temporary.bluetooth"
        static let wifiTemporaryActivityEnabled = "settings.temporary.wifi"
        static let vpnTemporaryActivityEnabled = "settings.temporary.vpn"
        static let focusOffTemporaryActivityEnabled = "settings.temporary.focusOff"
        static let notchSizeTemporaryActivityEnabled = "settings.temporary.notchSize"
    }

    static let defaultValues: [String: Any] = [
        Keys.launchAtLogin: true,
        Keys.notchWidth: 0,
        Keys.notchHeight: 0,
        Keys.menuBarIcon: true,
        Keys.notchStrokeEnabled: false,
        Keys.notchStrokeWidth: 1.5,
        Keys.displayLocation: NotchDisplayLocation.main.rawValue,
        Keys.brightnessHUDEnabled: true,
        Keys.keyboardHUDEnabled: true,
        Keys.volumeHUDEnabled: true,
        Keys.airDropLiveActivityEnabled: true,
        Keys.hotspotLiveActivityEnabled: true,
        Keys.focusLiveActivityEnabled: true,
        Keys.nowPlayingLiveActivityEnabled: true,
        LockScreenSettings.liveActivityKey: true,
        LockScreenSettings.mediaPanelKey: true,
        Keys.chargerTemporaryActivityEnabled: true,
        Keys.lowPowerTemporaryActivityEnabled: true,
        Keys.fullPowerTemporaryActivityEnabled: true,
        Keys.bluetoothTemporaryActivityEnabled: true,
        Keys.wifiTemporaryActivityEnabled: true,
        Keys.vpnTemporaryActivityEnabled: true,
        Keys.focusOffTemporaryActivityEnabled: true,
        Keys.notchSizeTemporaryActivityEnabled: true
    ]
}
