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

private enum GeneralSettingsStorage {
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

@MainActor
class SettingsStoreBase: ObservableObject {
    fileprivate let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
    }

    func persist(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: Double, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: String, for key: String) {
        defaults.set(value, forKey: key)
    }

    func defaultBool(for key: String) -> Bool {
        (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }

    func defaultInt(for key: String) -> Int {
        (GeneralSettingsStorage.defaultValues[key] as? Int) ?? 0
    }

    func defaultDouble(for key: String) -> Double {
        (GeneralSettingsStorage.defaultValues[key] as? Double) ?? 0
    }

    func defaultString(for key: String) -> String {
        (GeneralSettingsStorage.defaultValues[key] as? String) ?? ""
    }
}

@MainActor
final class ApplicationSettingsStore: SettingsStoreBase, NotchSettingsProviding {
    @Published var isLaunchAtLoginEnabled: Bool {
        didSet {
            persist(isLaunchAtLoginEnabled, for: GeneralSettingsStorage.Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var notchWidth: Int {
        didSet {
            guard oldValue != notchWidth else { return }
            persist(notchWidth, for: GeneralSettingsStorage.Keys.notchWidth)
            notchSizeEvent.send(.width)
        }
    }

    @Published var notchHeight: Int {
        didSet {
            guard oldValue != notchHeight else { return }
            persist(notchHeight, for: GeneralSettingsStorage.Keys.notchHeight)
            notchSizeEvent.send(.height)
        }
    }

    @Published var isMenuBarIconVisible: Bool {
        didSet {
            persist(isMenuBarIconVisible, for: GeneralSettingsStorage.Keys.menuBarIcon)
        }
    }

    @Published var isShowNotchStrokeEnabled: Bool {
        didSet {
            persist(isShowNotchStrokeEnabled, for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        }
    }

    @Published var notchStrokeWidth: Double {
        didSet {
            persist(notchStrokeWidth, for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        }
    }

    @Published var displayLocation: NotchDisplayLocation {
        didSet {
            persist(displayLocation.rawValue, for: GeneralSettingsStorage.Keys.displayLocation)
        }
    }

    @Published var notchAnimationPreset: NotchAnimationPreset {
        didSet {
            persist(notchAnimationPreset.rawValue, for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        }
    }

    @Published var isNotchSizeTemporaryActivityEnabled: Bool {
        didSet {
            persist(
                isNotchSizeTemporaryActivityEnabled,
                for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled
            )
        }
    }

    let notchSizeEvent = PassthroughSubject<NotchSizeEvent, Never>()

    override init(defaults: UserDefaults) {
        self.isLaunchAtLoginEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.launchAtLogin)
        self.notchWidth = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchWidth)
        self.notchHeight = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchHeight)
        self.isMenuBarIconVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.menuBarIcon)
        self.isShowNotchStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        self.notchStrokeWidth = defaults.double(forKey: GeneralSettingsStorage.Keys.notchStrokeWidth)
        self.displayLocation = NotchDisplayLocation(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue
        ) ?? .main
        self.notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.notchAnimationPreset) ?? NotchAnimationPreset.balanced.rawValue
        ) ?? .balanced
        self.isNotchSizeTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        super.init(defaults: defaults)
        updateLaunchAtLogin()
    }

    func reset() {
        isLaunchAtLoginEnabled = defaultBool(for: GeneralSettingsStorage.Keys.launchAtLogin)
        isMenuBarIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.menuBarIcon)
        displayLocation = NotchDisplayLocation(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.displayLocation)
        ) ?? .main
        notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        ) ?? .balanced
        isShowNotchStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        isNotchSizeTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        notchStrokeWidth = defaultDouble(for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        notchWidth = defaultInt(for: GeneralSettingsStorage.Keys.notchWidth)
        notchHeight = defaultInt(for: GeneralSettingsStorage.Keys.notchHeight)
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

@MainActor
final class MediaAndFilesSettingsStore: SettingsStoreBase {
    @Published var isNowPlayingLiveActivityEnabled: Bool {
        didSet {
            persist(isNowPlayingLiveActivityEnabled, for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        }
    }

    @Published var isDownloadsLiveActivityEnabled: Bool {
        didSet {
            persist(isDownloadsLiveActivityEnabled, for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        }
    }

    @Published var isDownloadsDefaultStrokeEnabled: Bool {
        didSet {
            persist(isDownloadsDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        }
    }

    @Published var isAirDropLiveActivityEnabled: Bool {
        didSet {
            persist(isAirDropLiveActivityEnabled, for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        }
    }

    @Published var isAirDropDefaultStrokeEnabled: Bool {
        didSet {
            persist(isAirDropDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        let hasLegacyDownloadsValue = defaults.object(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) != nil
        let downloadsSettingValue = defaults.object(forKey: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled) as? Bool
        self.isDownloadsLiveActivityEnabled = downloadsSettingValue ?? (
            hasLegacyDownloadsValue ?
            defaults.bool(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) :
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled] as? Bool ?? true)
        )
        self.isDownloadsDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        self.isAirDropLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        self.isAirDropDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func resetNowPlaying() {
        isNowPlayingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        isDownloadsDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
    }

    func resetAirDrop() {
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        isAirDropDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
    }
}

@MainActor
final class ConnectivitySettingsStore: SettingsStoreBase {
    @Published var isHotspotLiveActivityEnabled: Bool {
        didSet {
            persist(isHotspotLiveActivityEnabled, for: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        }
    }

    @Published var isFocusLiveActivityEnabled: Bool {
        didSet {
            persist(isFocusLiveActivityEnabled, for: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        }
    }

    @Published var isBluetoothTemporaryActivityEnabled: Bool {
        didSet {
            persist(isBluetoothTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
        }
    }

    @Published var isWifiTemporaryActivityEnabled: Bool {
        didSet {
            persist(isWifiTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        }
    }

    @Published var isVpnTemporaryActivityEnabled: Bool {
        didSet {
            persist(isVpnTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        }
    }

    @Published var isFocusOffTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFocusOffTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        }
    }

    @Published var isFocusDefaultStrokeEnabled: Bool {
        didSet {
            persist(isFocusDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled)
        }
    }

    @Published var isHotspotDefaultStrokeEnabled: Bool {
        didSet {
            persist(isHotspotDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isHotspotLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        self.isFocusLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        self.isBluetoothTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
        self.isWifiTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        self.isVpnTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        self.isFocusOffTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        self.isFocusDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled)
        self.isHotspotDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func resetFocus() {
        isFocusLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        isFocusOffTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        isFocusDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled)
    }

    func resetBluetooth() {
        isBluetoothTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
    }

    func resetNetwork() {
        isHotspotLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        isWifiTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        isVpnTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        isHotspotDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled)
    }
}

@MainActor
final class BatterySettingsStore: SettingsStoreBase {
    @Published var isChargerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isChargerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        }
    }

    @Published var isLowPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isLowPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        }
    }

    @Published var isFullPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFullPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        }
    }

    @Published var isBatteryDefaultStrokeEnabled: Bool {
        didSet {
            persist(isBatteryDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isChargerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        self.isBatteryDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isChargerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        isLowPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        isFullPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        isBatteryDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
    }
}

@MainActor
final class HUDSettingsStore: SettingsStoreBase {
    @Published var isBrightnessHUDEnabled: Bool {
        didSet {
            persist(isBrightnessHUDEnabled, for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        }
    }

    @Published var isKeyboardHUDEnabled: Bool {
        didSet {
            persist(isKeyboardHUDEnabled, for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        }
    }

    @Published var isVolumeHUDEnabled: Bool {
        didSet {
            persist(isVolumeHUDEnabled, for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isBrightnessHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        self.isKeyboardHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        self.isVolumeHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isBrightnessHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        isKeyboardHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        isVolumeHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
    }
}

@MainActor
final class LockScreenFeatureSettingsStore: SettingsStoreBase {
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

    override init(defaults: UserDefaults) {
        self.isLockScreenLiveActivityEnabled = defaults.bool(forKey: LockScreenSettings.liveActivityKey)
        self.isLockScreenSoundEnabled = defaults.bool(forKey: LockScreenSettings.soundKey)
        self.isLockScreenMediaPanelEnabled = defaults.bool(forKey: LockScreenSettings.mediaPanelKey)
        super.init(defaults: defaults)
    }

    func reset() {
        isLockScreenLiveActivityEnabled = defaultBool(for: LockScreenSettings.liveActivityKey)
        isLockScreenSoundEnabled = defaultBool(for: LockScreenSettings.soundKey)
        isLockScreenMediaPanelEnabled = defaultBool(for: LockScreenSettings.mediaPanelKey)
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

    let application: ApplicationSettingsStore
    let mediaAndFiles: MediaAndFilesSettingsStore
    let connectivity: ConnectivitySettingsStore
    let battery: BatterySettingsStore
    let hud: HUDSettingsStore
    let lockScreen: LockScreenFeatureSettingsStore

    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.application = ApplicationSettingsStore(defaults: defaults)
        self.mediaAndFiles = MediaAndFilesSettingsStore(defaults: defaults)
        self.connectivity = ConnectivitySettingsStore(defaults: defaults)
        self.battery = BatterySettingsStore(defaults: defaults)
        self.hud = HUDSettingsStore(defaults: defaults)
        self.lockScreen = LockScreenFeatureSettingsStore(defaults: defaults)
        bindStores()
    }

    var isLaunchAtLoginEnabled: Bool {
        get { application.isLaunchAtLoginEnabled }
        set { application.isLaunchAtLoginEnabled = newValue }
    }

    var notchWidth: Int {
        get { application.notchWidth }
        set { application.notchWidth = newValue }
    }

    var notchHeight: Int {
        get { application.notchHeight }
        set { application.notchHeight = newValue }
    }

    var isMenuBarIconVisible: Bool {
        get { application.isMenuBarIconVisible }
        set { application.isMenuBarIconVisible = newValue }
    }

    var isShowNotchStrokeEnabled: Bool {
        get { application.isShowNotchStrokeEnabled }
        set { application.isShowNotchStrokeEnabled = newValue }
    }

    var notchStrokeWidth: Double {
        get { application.notchStrokeWidth }
        set { application.notchStrokeWidth = newValue }
    }

    var displayLocation: NotchDisplayLocation {
        get { application.displayLocation }
        set { application.displayLocation = newValue }
    }

    var notchAnimationPreset: NotchAnimationPreset {
        get { application.notchAnimationPreset }
        set { application.notchAnimationPreset = newValue }
    }

    var isNotchSizeTemporaryActivityEnabled: Bool {
        get { application.isNotchSizeTemporaryActivityEnabled }
        set { application.isNotchSizeTemporaryActivityEnabled = newValue }
    }

    var notchSizeEvent: PassthroughSubject<NotchSizeEvent, Never> {
        application.notchSizeEvent
    }

    var isBrightnessHUDEnabled: Bool {
        get { hud.isBrightnessHUDEnabled }
        set { hud.isBrightnessHUDEnabled = newValue }
    }

    var isKeyboardHUDEnabled: Bool {
        get { hud.isKeyboardHUDEnabled }
        set { hud.isKeyboardHUDEnabled = newValue }
    }

    var isVolumeHUDEnabled: Bool {
        get { hud.isVolumeHUDEnabled }
        set { hud.isVolumeHUDEnabled = newValue }
    }

    var isHotspotLiveActivityEnabled: Bool {
        get { connectivity.isHotspotLiveActivityEnabled }
        set { connectivity.isHotspotLiveActivityEnabled = newValue }
    }

    var isFocusLiveActivityEnabled: Bool {
        get { connectivity.isFocusLiveActivityEnabled }
        set { connectivity.isFocusLiveActivityEnabled = newValue }
    }

    var isNowPlayingLiveActivityEnabled: Bool {
        get { mediaAndFiles.isNowPlayingLiveActivityEnabled }
        set { mediaAndFiles.isNowPlayingLiveActivityEnabled = newValue }
    }

    var isLockScreenLiveActivityEnabled: Bool {
        get { lockScreen.isLockScreenLiveActivityEnabled }
        set { lockScreen.isLockScreenLiveActivityEnabled = newValue }
    }

    var isLockScreenSoundEnabled: Bool {
        get { lockScreen.isLockScreenSoundEnabled }
        set { lockScreen.isLockScreenSoundEnabled = newValue }
    }

    var isLockScreenMediaPanelEnabled: Bool {
        get { lockScreen.isLockScreenMediaPanelEnabled }
        set { lockScreen.isLockScreenMediaPanelEnabled = newValue }
    }

    var isDownloadsLiveActivityEnabled: Bool {
        get { mediaAndFiles.isDownloadsLiveActivityEnabled }
        set { mediaAndFiles.isDownloadsLiveActivityEnabled = newValue }
    }

    var isDownloadsDefaultStrokeEnabled: Bool {
        get { mediaAndFiles.isDownloadsDefaultStrokeEnabled }
        set { mediaAndFiles.isDownloadsDefaultStrokeEnabled = newValue }
    }

    var isAirDropLiveActivityEnabled: Bool {
        get { mediaAndFiles.isAirDropLiveActivityEnabled }
        set { mediaAndFiles.isAirDropLiveActivityEnabled = newValue }
    }

    var isAirDropDefaultStrokeEnabled: Bool {
        get { mediaAndFiles.isAirDropDefaultStrokeEnabled }
        set { mediaAndFiles.isAirDropDefaultStrokeEnabled = newValue }
    }

    var isChargerTemporaryActivityEnabled: Bool {
        get { battery.isChargerTemporaryActivityEnabled }
        set { battery.isChargerTemporaryActivityEnabled = newValue }
    }

    var isLowPowerTemporaryActivityEnabled: Bool {
        get { battery.isLowPowerTemporaryActivityEnabled }
        set { battery.isLowPowerTemporaryActivityEnabled = newValue }
    }

    var isFullPowerTemporaryActivityEnabled: Bool {
        get { battery.isFullPowerTemporaryActivityEnabled }
        set { battery.isFullPowerTemporaryActivityEnabled = newValue }
    }

    var isBluetoothTemporaryActivityEnabled: Bool {
        get { connectivity.isBluetoothTemporaryActivityEnabled }
        set { connectivity.isBluetoothTemporaryActivityEnabled = newValue }
    }

    var isWifiTemporaryActivityEnabled: Bool {
        get { connectivity.isWifiTemporaryActivityEnabled }
        set { connectivity.isWifiTemporaryActivityEnabled = newValue }
    }

    var isVpnTemporaryActivityEnabled: Bool {
        get { connectivity.isVpnTemporaryActivityEnabled }
        set { connectivity.isVpnTemporaryActivityEnabled = newValue }
    }

    var isFocusOffTemporaryActivityEnabled: Bool {
        get { connectivity.isFocusOffTemporaryActivityEnabled }
        set { connectivity.isFocusOffTemporaryActivityEnabled = newValue }
    }

    var isFocusDefaultStrokeEnabled: Bool {
        get { connectivity.isFocusDefaultStrokeEnabled }
        set { connectivity.isFocusDefaultStrokeEnabled = newValue }
    }

    var isHotspotDefaultStrokeEnabled: Bool {
        get { connectivity.isHotspotDefaultStrokeEnabled }
        set { connectivity.isHotspotDefaultStrokeEnabled = newValue }
    }

    var isBatteryDefaultStrokeEnabled: Bool {
        get { battery.isBatteryDefaultStrokeEnabled }
        set { battery.isBatteryDefaultStrokeEnabled = newValue }
    }

    func isLiveActivityEnabled(_ preference: LiveActivityPreference) -> Bool {
        switch preference {
        case .hotspot:
            return connectivity.isHotspotLiveActivityEnabled
        case .focus:
            return connectivity.isFocusLiveActivityEnabled
        case .nowPlaying:
            return mediaAndFiles.isNowPlayingLiveActivityEnabled
        case .lockScreen:
            return lockScreen.isLockScreenLiveActivityEnabled
        case .downloads:
            return mediaAndFiles.isDownloadsLiveActivityEnabled
        case .airDrop:
            return mediaAndFiles.isAirDropLiveActivityEnabled
        }
    }

    func isHUDEnabled(_ preference: HUDPreference) -> Bool {
        switch preference {
        case .brightness:
            return hud.isBrightnessHUDEnabled
        case .keyboard:
            return hud.isKeyboardHUDEnabled
        case .volume:
            return hud.isVolumeHUDEnabled
        }
    }

    func isTemporaryActivityEnabled(_ preference: TemporaryActivityPreference) -> Bool {
        switch preference {
        case .charger:
            return battery.isChargerTemporaryActivityEnabled
        case .lowPower:
            return battery.isLowPowerTemporaryActivityEnabled
        case .fullPower:
            return battery.isFullPowerTemporaryActivityEnabled
        case .bluetooth:
            return connectivity.isBluetoothTemporaryActivityEnabled
        case .wifi:
            return connectivity.isWifiTemporaryActivityEnabled
        case .vpn:
            return connectivity.isVpnTemporaryActivityEnabled
        case .focusOff:
            return connectivity.isFocusOffTemporaryActivityEnabled
        case .notchSize:
            return application.isNotchSizeTemporaryActivityEnabled
        }
    }

    func reset(_ group: ResetGroup) {
        switch group {
        case .general:
            application.reset()
        case .nowPlaying:
            mediaAndFiles.resetNowPlaying()
        case .downloads:
            mediaAndFiles.resetDownloads()
        case .airDrop:
            mediaAndFiles.resetAirDrop()
        case .focus:
            connectivity.resetFocus()
        case .bluetooth:
            connectivity.resetBluetooth()
        case .network:
            connectivity.resetNetwork()
        case .battery:
            battery.reset()
        case .hud:
            hud.reset()
        case .lockScreen:
            lockScreen.reset()
        }
    }

    private func bindStores() {
        bind(store: application)
        bind(store: mediaAndFiles)
        bind(store: connectivity)
        bind(store: battery)
        bind(store: hud)
        bind(store: lockScreen)
    }

    private func bind<Object: ObservableObject>(store: Object)
    where Object.ObjectWillChangePublisher == ObservableObjectPublisher {
        store.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
