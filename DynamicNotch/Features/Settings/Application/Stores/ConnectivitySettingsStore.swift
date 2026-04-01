import Foundation
import Combine

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
