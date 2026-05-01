import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject, NotchSettingsProviding {
    enum ResetGroup {
        case general
        case notch
        case nowPlaying
        case downloads
        case drop
        case timer
        case focus
        case bluetooth
        case network
        case battery
        case hud
        case lockScreen
        case screenRecording
    }

    enum LiveActivityPreference {
        case hotspot
        case focus
        case nowPlaying
        case lockScreen
        case downloads
        case drop
        case timer
        case screenRecording
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
    let screenRecording: ScreenRecordingSettingsStore
    private let defaults: UserDefaults

    private var cancellables = Set<AnyCancellable>()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.application = ApplicationSettingsStore(defaults: defaults)
        self.mediaAndFiles = MediaAndFilesSettingsStore(defaults: defaults)
        self.connectivity = ConnectivitySettingsStore(defaults: defaults)
        self.battery = BatterySettingsStore(defaults: defaults)
        self.hud = HUDSettingsStore(defaults: defaults)
        self.lockScreen = LockScreenFeatureSettingsStore(defaults: defaults)
        self.screenRecording = ScreenRecordingSettingsStore(defaults: defaults)
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

    var screenSelectionPreferences: NotchScreenSelectionPreferences {
        application.screenSelectionPreferences
    }

    var appLanguage: DynamicNotchLanguage {
        get { application.appLanguage }
        set { application.appLanguage = newValue }
    }

    var notchAnimationPreset: NotchAnimationPreset {
        get { application.notchAnimationPreset }
        set { application.notchAnimationPreset = newValue }
    }

    var isNotchTapToExpandEnabled: Bool {
        get { application.isNotchTapToExpandEnabled }
        set { application.isNotchTapToExpandEnabled = newValue }
    }

    var notchExpandInteraction: NotchExpandInteraction {
        get { application.notchExpandInteraction }
        set { application.notchExpandInteraction = newValue }
    }

    var notchPressHoldDuration: TimeInterval {
        get { application.notchPressHoldDuration }
        set { application.notchPressHoldDuration = newValue }
    }

    var isNotchMouseDragGesturesEnabled: Bool {
        get { application.isNotchMouseDragGesturesEnabled }
        set { application.isNotchMouseDragGesturesEnabled = newValue }
    }

    var isNotchTrackpadSwipeGesturesEnabled: Bool {
        get { application.isNotchTrackpadSwipeGesturesEnabled }
        set { application.isNotchTrackpadSwipeGesturesEnabled = newValue }
    }

    var isNotchSwipeDismissEnabled: Bool {
        get { application.isNotchSwipeDismissEnabled }
        set { application.isNotchSwipeDismissEnabled = newValue }
    }

    var isNotchSwipeRestoreEnabled: Bool {
        get { application.isNotchSwipeRestoreEnabled }
        set { application.isNotchSwipeRestoreEnabled = newValue }
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
        get { application.isDefaultActivityStrokeEnabled ? false : hud.isColoredLevelStrokeEnabled }
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

    var isDragAndDropLiveActivityEnabled: Bool {
        get { mediaAndFiles.isDragAndDropLiveActivityEnabled }
        set { mediaAndFiles.isDragAndDropLiveActivityEnabled = newValue }
    }

    var isTimerLiveActivityEnabled: Bool {
        get { mediaAndFiles.isTimerLiveActivityEnabled }
        set { mediaAndFiles.isTimerLiveActivityEnabled = newValue }
    }

    var isScreenRecordingLiveActivityEnabled: Bool {
        get { screenRecording.isScreenRecordingLiveActivityEnabled }
        set { screenRecording.isScreenRecordingLiveActivityEnabled = newValue }
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

    var isNoInternetTemporaryActivityEnabled: Bool {
        get { connectivity.isNoInternetTemporaryActivityEnabled }
        set { connectivity.isNoInternetTemporaryActivityEnabled = newValue }
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
        case .drop:
            return mediaAndFiles.isDragAndDropLiveActivityEnabled
        case .timer:
            return mediaAndFiles.isTimerLiveActivityEnabled
        case .screenRecording:
            return screenRecording.isScreenRecordingLiveActivityEnabled
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

    func temporaryActivityDuration(for preference: TemporaryActivityPreference) -> TimeInterval {
        switch preference {
        case .charger:
            return scaledTemporaryActivityDuration(TimeInterval(battery.chargerTemporaryActivityDuration))
        case .lowPower:
            return scaledTemporaryActivityDuration(TimeInterval(battery.lowPowerTemporaryActivityDuration))
        case .fullPower:
            return scaledTemporaryActivityDuration(TimeInterval(battery.fullPowerTemporaryActivityDuration))
        case .bluetooth:
            return scaledTemporaryActivityDuration(TimeInterval(connectivity.bluetoothTemporaryActivityDuration))
        case .wifi:
            return scaledTemporaryActivityDuration(TimeInterval(connectivity.wifiTemporaryActivityDuration))
        case .vpn:
            return scaledTemporaryActivityDuration(TimeInterval(connectivity.vpnTemporaryActivityDuration))
        case .focusOff:
            return scaledTemporaryActivityDuration(TimeInterval(connectivity.focusOffTemporaryActivityDuration))
        case .notchSize:
            return scaledTemporaryActivityDuration(TimeInterval(application.notchSizeTemporaryActivityDuration))
        }
    }

    func temporaryActivityDuration(for preference: HUDPreference) -> TimeInterval {
        switch preference {
        case .brightness:
            return scaledTemporaryActivityDuration(TimeInterval(hud.brightnessHUDDuration))
        case .keyboard:
            return scaledTemporaryActivityDuration(TimeInterval(hud.keyboardHUDDuration))
        case .volume:
            return scaledTemporaryActivityDuration(TimeInterval(hud.volumeHUDDuration))
        }
    }

    private func scaledTemporaryActivityDuration(_ duration: TimeInterval) -> TimeInterval {
        duration * temporaryActivityDurationScale
    }

    private var temporaryActivityDurationScale: Double {
        let storedScale = defaults.object(forKey: GeneralSettingsStorage.Keys.temporaryActivityDurationScale) as? Double
        let defaultScale = (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.temporaryActivityDurationScale] as? Double) ?? 1
        return max(storedScale ?? defaultScale, 0)
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
        case .drop:
            mediaAndFiles.resetDragAndDrop()
        case .timer:
            mediaAndFiles.resetTimer()
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
        case .screenRecording:
            screenRecording.reset()
        }
    }

    private func bindStores() {
        bind(store: application)
        bind(store: mediaAndFiles)
        bind(store: connectivity)
        bind(store: battery)
        bind(store: hud)
        bind(store: lockScreen)
        bind(store: screenRecording)
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
