import Foundation
import Combine

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

    @Published var hudStyle: HudStyle {
        didSet {
            persist(hudStyle.rawValue, for: GeneralSettingsStorage.Keys.hudStyle)
        }
    }

    @Published var indicatorStyle: HudIndicatorStyle {
        didSet {
            persist(indicatorStyle.rawValue, for: GeneralSettingsStorage.Keys.hudIndicatorStyle)
        }
    }

    @Published var isColoredLevelEnabled: Bool {
        didSet {
            persist(isColoredLevelEnabled, for: GeneralSettingsStorage.Keys.hudColoredLevelEnabled)
        }
    }

    @Published var isColoredLevelStrokeEnabled: Bool {
        didSet {
            persist(isColoredLevelStrokeEnabled, for: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isBrightnessHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        self.isKeyboardHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        self.isVolumeHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        self.hudStyle = HudStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.hudStyle) ?? HudStyle.standard.rawValue
        ) ?? .standard
        self.indicatorStyle = HudIndicatorStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.hudIndicatorStyle) ?? HudIndicatorStyle.bar.rawValue
        ) ?? .bar
        self.isColoredLevelEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hudColoredLevelEnabled)
        self.isColoredLevelStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isBrightnessHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        isKeyboardHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        isVolumeHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        hudStyle = HudStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.hudStyle)) ?? .standard
        indicatorStyle = HudIndicatorStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.hudIndicatorStyle)) ?? .bar
        isColoredLevelEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudColoredLevelEnabled)
        isColoredLevelStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
    }
}
