import Foundation
import Combine

extension FocusAppearanceStyle: StoredSettingValue {}
extension BluetoothAppearanceStyle: StoredSettingValue {}
extension BluetoothBatteryIndicatorStyle: StoredSettingValue {}
extension HotspotAppearanceStyle: StoredSettingValue {}

@MainActor
final class ConnectivitySettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled, defaultValue: false)
    var isHotspotLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.focusLiveActivityEnabled, defaultValue: true)
    var isFocusLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.focusOnAutoHideEnabled, defaultValue: false)
    var isFocusOnAutoHideEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.focusOnTemporaryActivityDuration,
        defaultValue: 3,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var focusOnTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.focusAppearanceStyle, defaultValue: .iconsOnly)
    var focusAppearanceStyle: FocusAppearanceStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled, defaultValue: false)
    var isFocusDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled, defaultValue: true)
    var isBluetoothTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var bluetoothTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.bluetoothAppearanceStyle, defaultValue: .detailed)
    var bluetoothAppearanceStyle: BluetoothAppearanceStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.bluetoothBatteryStrokeEnabled, defaultValue: false)
    var isBluetoothBatteryStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.bluetoothBatteryIndicatorStyle, defaultValue: .percent)
    var bluetoothBatteryIndicatorStyle: BluetoothBatteryIndicatorStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled, defaultValue: true)
    var isWifiTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration,
        defaultValue: 3,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var wifiTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled, defaultValue: true)
    var isVpnTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var vpnTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.vpnDisconnectedTemporaryActivityEnabled, defaultValue: true)
    var isVpnDisconnectedTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.vpnDisconnectedTemporaryActivityDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var vpnDisconnectedTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.noInternetTemporaryActivityEnabled, defaultValue: true)
    var isNoInternetTemporaryActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.networkShowVPNDetail, defaultValue: false)
    var isVPNDetailVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.hotspotAppearanceStyle, defaultValue: .minimal)
    var hotspotAppearanceStyle: HotspotAppearanceStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled, defaultValue: false)
    var isHotspotDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.networkShowVPNTimer, defaultValue: true)
    var isVPNTimerVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.selectedVPNID, defaultValue: "")
    var selectedVPNID: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled, defaultValue: true)
    var isFocusOffTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration,
        defaultValue: 3,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var focusOffTemporaryActivityDuration: Int

    override init(defaults: UserDefaults) {
        super.init(defaults: defaults)
    }

    func resetBluetooth() {
        isBluetoothTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
        bluetoothTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration)
        bluetoothAppearanceStyle = .detailed
        isBluetoothBatteryStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.bluetoothBatteryStrokeEnabled)
        bluetoothBatteryIndicatorStyle = .percent
    }

    func resetWifi() {
        isHotspotLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        isWifiTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        wifiTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration)
        isNoInternetTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.noInternetTemporaryActivityEnabled)
        hotspotAppearanceStyle = .minimal
        isHotspotDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled)
    }

    func resetVpn() {
        isVpnTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        vpnTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration)
        isVpnDisconnectedTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.vpnDisconnectedTemporaryActivityEnabled)
        vpnDisconnectedTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.vpnDisconnectedTemporaryActivityDuration)
        isVPNDetailVisible = defaultBool(for: GeneralSettingsStorage.Keys.networkShowVPNDetail)
        isVPNTimerVisible = defaultBool(for: GeneralSettingsStorage.Keys.networkShowVPNTimer)
        selectedVPNID = defaultString(for: GeneralSettingsStorage.Keys.selectedVPNID)
    }

    func resetFocus() {
        isFocusLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        isFocusOnAutoHideEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusOnAutoHideEnabled)
        focusOnTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.focusOnTemporaryActivityDuration)
        focusAppearanceStyle = .iconsOnly
        isFocusDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled)
        isFocusOffTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        focusOffTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration)
    }
}
