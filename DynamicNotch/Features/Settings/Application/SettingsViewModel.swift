import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject, NotchSettingsProviding {
    enum ResetGroup {
        case general
        case notch
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

    var isDockIconVisible: Bool {
        get { application.isDockIconVisible }
        set { application.isDockIconVisible = newValue }
    }

    var appearanceMode: SettingsAppearanceMode {
        get { application.appearanceMode }
        set { application.appearanceMode = newValue }
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

    var isDefaultActivityStrokeEnabled: Bool {
        get { application.isDefaultActivityStrokeEnabled }
        set { application.isDefaultActivityStrokeEnabled = newValue }
    }

    var notchStrokeWidth: Double {
        get { application.notchStrokeWidth }
        set { application.notchStrokeWidth = newValue }
    }

    var displayLocation: NotchDisplayLocation {
        get { application.displayLocation }
        set { application.displayLocation = newValue }
    }

    var appLanguage: DynamicNotchLanguage {
        get { application.appLanguage }
        set { application.appLanguage = newValue }
    }

    var notchAnimationPreset: NotchAnimationPreset {
        get { application.notchAnimationPreset }
        set { application.notchAnimationPreset = newValue }
    }

    var temporaryActivityDurationScale: Double {
        get { application.temporaryActivityDurationScale }
        set { application.temporaryActivityDurationScale = newValue }
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

    var hudStyle: HudStyle {
        get { hud.hudStyle }
        set { hud.hudStyle = newValue }
    }

    var hudIndicatorStyle: HudIndicatorStyle {
        get { hud.indicatorStyle }
        set { hud.indicatorStyle = newValue }
    }

    var isHUDColoredLevelEnabled: Bool {
        get { hud.isColoredLevelEnabled }
        set { hud.isColoredLevelEnabled = newValue }
    }

    var isHUDColoredLevelStrokeEnabled: Bool {
        get { hud.isColoredLevelStrokeEnabled }
        set { hud.isColoredLevelStrokeEnabled = newValue }
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

    var isAirDropLiveActivityEnabled: Bool {
        get { mediaAndFiles.isAirDropLiveActivityEnabled }
        set { mediaAndFiles.isAirDropLiveActivityEnabled = newValue }
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

    func resolvedTemporaryActivityDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        max(0.2, baseDuration * application.temporaryActivityDurationScale)
    }

    func reset(_ group: ResetGroup) {
        switch group {
        case .general:
            application.resetGeneral()
        case .notch:
            application.resetNotch()
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
