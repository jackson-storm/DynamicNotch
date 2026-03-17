import Combine
import SwiftUI

@MainActor
final class TemporaryActivitySettingsViewModel: ObservableObject {
    private let settings: GeneralSettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    init(settings: GeneralSettingsViewModel) {
        self.settings = settings

        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var groups: [SettingsToggleGroup] {
        [
            SettingsToggleGroup(
                id: "temporary.power",
                title: "Power and battery",
                subtitle: "Short-lived notifications for charging state changes.",
                items: [
                    SettingsToggleItem(
                        id: "temporary.charger",
                        title: "Charging",
                        description: "Show a temporary card when power is connected.",
                        systemImage: "bolt.fill",
                        color: .green,
                        accessibilityIdentifier: "settings.activities.temporary.charger",
                        keyPath: \.isChargerTemporaryActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "temporary.lowPower",
                        title: "Low Power",
                        description: "Warn when Low Power Mode or a critical battery level is detected.",
                        systemImage: "battery.25",
                        color: .green,
                        accessibilityIdentifier: "settings.activities.temporary.lowPower",
                        keyPath: \.isLowPowerTemporaryActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "temporary.fullPower",
                        title: "Fully Charged",
                        description: "Celebrate a full battery with a brief notification.",
                        systemImage: "battery.100",
                        color: .green,
                        accessibilityIdentifier: "settings.activities.temporary.fullPower",
                        keyPath: \.isFullPowerTemporaryActivityEnabled
                    )
                ]
            ),
            SettingsToggleGroup(
                id: "temporary.connectivity",
                title: "Connectivity",
                subtitle: "Transient confirmations when network-related events occur.",
                items: [
                    SettingsToggleItem(
                        id: "temporary.bluetooth",
                        title: "Bluetooth devices",
                        description: "Show a card when a Bluetooth accessory connects.",
                        systemImage: "headphones",
                        color: .blue,
                        accessibilityIdentifier: "settings.activities.temporary.bluetooth",
                        keyPath: \.isBluetoothTemporaryActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "temporary.wifi",
                        title: "Wi-Fi connected",
                        description: "Display a brief toast when Wi-Fi reconnects.",
                        systemImage: "wifi",
                        color: .blue,
                        accessibilityIdentifier: "settings.activities.temporary.wifi",
                        keyPath: \.isWifiTemporaryActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "temporary.vpn",
                        title: "VPN connected",
                        description: "Show a temporary confirmation when a VPN tunnel becomes active.",
                        systemImage: "network",
                        color: .blue,
                        accessibilityIdentifier: "settings.activities.temporary.vpn",
                        keyPath: \.isVpnTemporaryActivityEnabled
                    )
                ]
            ),
            SettingsToggleGroup(
                    id: "hud",
                    title: "HUD",
                    subtitle: "Choose which hardware overlays Dynamic Notch should handle.",
                    items: [
                        SettingsToggleItem(
                            id: "hud.brightness",
                            title: "Brightness HUD",
                            description: "Show the custom notch HUD for display brightness changes.",
                            systemImage: "sun.max.fill",
                            color: .orange,
                            accessibilityIdentifier: "settings.general.hud.brightness",
                            keyPath: \.isBrightnessHUDEnabled
                        ),
                        SettingsToggleItem(
                            id: "hud.keyboard",
                            title: "Keyboard HUD",
                            description: "Show the custom notch HUD for keyboard backlight changes.",
                            systemImage: "light.max",
                            color: .orange,
                            accessibilityIdentifier: "settings.general.hud.keyboard",
                            keyPath: \.isKeyboardHUDEnabled
                        ),
                        SettingsToggleItem(
                            id: "hud.volume",
                            title: "Volume HUD",
                            description: "Show the custom notch HUD for output volume changes.",
                            systemImage: "speaker.wave.2.fill",
                            color: .orange,
                            accessibilityIdentifier: "settings.general.hud.volume",
                            keyPath: \.isVolumeHUDEnabled
                        )
                    ]
                ),
            SettingsToggleGroup(
                id: "temporary.utility",
                title: "Utility",
                subtitle: "Short helpers that give feedback during quick interactions.",
                items: [
                    SettingsToggleItem(
                        id: "temporary.focusOff",
                        title: "Focus mode off",
                        description: "Show a quick state change message when Focus mode is disabled.",
                        systemImage: "moon.stars.fill",
                        color: .indigo,
                        accessibilityIdentifier: "settings.activities.temporary.focusOff",
                        keyPath: \.isFocusOffTemporaryActivityEnabled
                    ),
                    SettingsToggleItem(
                        id: "temporary.notchSize",
                        title: "Resize feedback",
                        description: "Show temporary notch-size hints while width or height sliders are adjusted.",
                        systemImage: "arrow.up.left.and.arrow.down.right",
                        color: .red,
                        accessibilityIdentifier: "settings.activities.temporary.notchSize",
                        keyPath: \.isNotchSizeTemporaryActivityEnabled
                    )
                ]
            )
        ]
    }

    func binding(for item: SettingsToggleItem) -> Binding<Bool> {
        Binding(
            get: { self.settings[keyPath: item.keyPath] },
            set: { self.settings[keyPath: item.keyPath] = $0 }
        )
    }
}
