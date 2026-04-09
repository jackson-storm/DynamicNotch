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

    @Published var bluetoothTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(bluetoothTemporaryActivityDuration)
            if clampedValue != bluetoothTemporaryActivityDuration {
                bluetoothTemporaryActivityDuration = clampedValue
                return
            }

            persist(bluetoothTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration)
        }
    }

    @Published var isWifiTemporaryActivityEnabled: Bool {
        didSet {
            persist(isWifiTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        }
    }

    @Published var wifiTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(wifiTemporaryActivityDuration)
            if clampedValue != wifiTemporaryActivityDuration {
                wifiTemporaryActivityDuration = clampedValue
                return
            }

            persist(wifiTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration)
        }
    }

    @Published var isVpnTemporaryActivityEnabled: Bool {
        didSet {
            persist(isVpnTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        }
    }

    @Published var vpnTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(vpnTemporaryActivityDuration)
            if clampedValue != vpnTemporaryActivityDuration {
                vpnTemporaryActivityDuration = clampedValue
                return
            }

            persist(vpnTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration)
        }
    }

    @Published var isVPNDetailVisible: Bool {
        didSet {
            persist(isVPNDetailVisible, for: GeneralSettingsStorage.Keys.networkShowVPNDetail)
        }
    }
    
    @Published var hotspotAppearanceStyle: HotspotAppearanceStyle {
        didSet {
            persist(hotspotAppearanceStyle.rawValue, for: GeneralSettingsStorage.Keys.hotspotAppearanceStyle)
        }
    }

    @Published var isVPNTimerVisible: Bool {
        didSet {
            persist(isVPNTimerVisible, for: GeneralSettingsStorage.Keys.networkShowVPNTimer)
        }
    }

    @Published var isOnlyNotifyOnNetworkChangeEnabled: Bool {
        didSet {
            persist(isOnlyNotifyOnNetworkChangeEnabled, for: GeneralSettingsStorage.Keys.networkOnlyNotifyOnChange)
        }
    }

    @Published var isFocusOffTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFocusOffTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        }
    }

    @Published var focusOffTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(focusOffTemporaryActivityDuration)
            if clampedValue != focusOffTemporaryActivityDuration {
                focusOffTemporaryActivityDuration = clampedValue
                return
            }

            persist(focusOffTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration)
        }
    }

    override init(defaults: UserDefaults) {
        self.isHotspotLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        self.isFocusLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        self.isBluetoothTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
        self.bluetoothTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration)
        )
        self.isWifiTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        self.wifiTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration)
        )
        self.isVpnTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        self.vpnTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration)
        )
        self.isVPNDetailVisible = defaults.object(forKey: GeneralSettingsStorage.Keys.networkShowVPNDetail) as? Bool ??
        (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.networkShowVPNDetail] as? Bool ?? true)
        self.hotspotAppearanceStyle = HotspotAppearanceStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.hotspotAppearanceStyle) ??
            HotspotAppearanceStyle.minimal.rawValue
        ) ?? .minimal
        self.isVPNTimerVisible = defaults.object(forKey: GeneralSettingsStorage.Keys.networkShowVPNTimer) as? Bool ??
        (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.networkShowVPNTimer] as? Bool ?? true)
        self.isOnlyNotifyOnNetworkChangeEnabled = defaults.object(forKey: GeneralSettingsStorage.Keys.networkOnlyNotifyOnChange) as? Bool ??
        (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.networkOnlyNotifyOnChange] as? Bool ?? false)
        self.isFocusOffTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        self.focusOffTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration)
        )
        super.init(defaults: defaults)
    }

    func resetBluetooth() {
        isBluetoothTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityEnabled)
        bluetoothTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.bluetoothTemporaryActivityDuration)
        )
    }

    func resetNetwork() {
        isHotspotLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hotspotLiveActivityEnabled)
        isWifiTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityEnabled)
        wifiTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.wifiTemporaryActivityDuration)
        )
        isVpnTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityEnabled)
        vpnTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.vpnTemporaryActivityDuration)
        )
        isVPNDetailVisible = defaultBool(for: GeneralSettingsStorage.Keys.networkShowVPNDetail)
        hotspotAppearanceStyle = HotspotAppearanceStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.hotspotAppearanceStyle)) ?? .minimal
        isVPNTimerVisible = defaultBool(for: GeneralSettingsStorage.Keys.networkShowVPNTimer)
        isOnlyNotifyOnNetworkChangeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.networkOnlyNotifyOnChange)
    }

    func resetFocus() {
        isFocusLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusLiveActivityEnabled)
        isFocusOffTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityEnabled)
        focusOffTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.focusOffTemporaryActivityDuration)
        )
    }
}
