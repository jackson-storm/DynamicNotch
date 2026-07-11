import Foundation
import Combine

@MainActor
final class HUDSettingsStore: SettingsStoreBase {
    @Published var isBrightnessHUDEnabled: Bool {
        didSet {
            persist(isBrightnessHUDEnabled, for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        }
    }

    @Published var brightnessHUDDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(brightnessHUDDuration)
            if clampedValue != brightnessHUDDuration {
                brightnessHUDDuration = clampedValue
                return
            }

            persist(brightnessHUDDuration, for: GeneralSettingsStorage.Keys.brightnessHUDDuration)
        }
    }

    @Published var isKeyboardHUDEnabled: Bool {
        didSet {
            persist(isKeyboardHUDEnabled, for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        }
    }

    @Published var keyboardHUDDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(keyboardHUDDuration)
            if clampedValue != keyboardHUDDuration {
                keyboardHUDDuration = clampedValue
                return
            }

            persist(keyboardHUDDuration, for: GeneralSettingsStorage.Keys.keyboardHUDDuration)
        }
    }

    @Published var isVolumeHUDEnabled: Bool {
        didSet {
            persist(isVolumeHUDEnabled, for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        }
    }

    @Published var isVolumeFeedbackSoundEnabled: Bool {
        didSet {
            persist(isVolumeFeedbackSoundEnabled, for: GeneralSettingsStorage.Keys.volumeFeedbackSoundEnabled)
        }
    }

    @Published var volumeHUDDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(volumeHUDDuration)
            if clampedValue != volumeHUDDuration {
                volumeHUDDuration = clampedValue
                return
            }

            persist(volumeHUDDuration, for: GeneralSettingsStorage.Keys.volumeHUDDuration)
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

    @Published var indicatorTintStyle: HudIndicatorTintStyle {
        didSet {
            persist(indicatorTintStyle.rawValue, for: GeneralSettingsStorage.Keys.hudIndicatorTintStyle)
        }
    }

    @Published var isIndicatorGlowEnabled: Bool {
        didSet {
            persist(isIndicatorGlowEnabled, for: GeneralSettingsStorage.Keys.hudIndicatorGlowEnabled)
        }
    }

    @Published var isColoredLevelStrokeEnabled: Bool {
        didSet {
            persist(isColoredLevelStrokeEnabled, for: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        let storedIndicatorTintStyle = defaults.string(forKey: GeneralSettingsStorage.Keys.hudIndicatorTintStyle)
        let legacyColoredLevel = defaults.object(
            forKey: GeneralSettingsStorage.Keys.hudColoredLevelEnabled
        ) as? Bool

        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isBrightnessHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        self.brightnessHUDDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.brightnessHUDDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.brightnessHUDDuration)
        )
        self.isKeyboardHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        self.keyboardHUDDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.keyboardHUDDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.keyboardHUDDuration)
        )
        self.isVolumeHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        self.isVolumeFeedbackSoundEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.volumeFeedbackSoundEnabled)
        self.volumeHUDDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.volumeHUDDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.volumeHUDDuration)
        )
        self.hudStyle = HudStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.hudStyle) ?? HudStyle.compact.rawValue
        ) ?? .compact
        self.indicatorStyle = HudIndicatorStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.hudIndicatorStyle) ?? HudIndicatorStyle.bar.rawValue
        ) ?? .bar
        self.indicatorTintStyle = Self.resolvedIndicatorTintStyle(
            storedRawValue: storedIndicatorTintStyle,
            legacyColoredLevel: legacyColoredLevel
        )
        self.isIndicatorGlowEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hudIndicatorGlowEnabled)
        self.isColoredLevelStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isBrightnessHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        brightnessHUDDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.brightnessHUDDuration)
        )
        isKeyboardHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        keyboardHUDDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.keyboardHUDDuration)
        )
        isVolumeHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        isVolumeFeedbackSoundEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeFeedbackSoundEnabled)
        volumeHUDDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.volumeHUDDuration)
        )
        hudStyle = HudStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.hudStyle)) ?? .compact
        indicatorStyle = HudIndicatorStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.hudIndicatorStyle)) ?? .bar
        indicatorTintStyle = HudIndicatorTintStyle(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.hudIndicatorTintStyle)
        ) ?? .levelColor
        isIndicatorGlowEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudIndicatorGlowEnabled)
        isColoredLevelStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
    }

    private static func resolvedIndicatorTintStyle(
        storedRawValue: String?,
        legacyColoredLevel: Bool?
    ) -> HudIndicatorTintStyle {
        if let rawValue = storedRawValue,
           let style = HudIndicatorTintStyle(rawValue: rawValue) {
            return style
        }

        if let legacyColoredLevel {
            return legacyColoredLevel ? .levelColor : .plainWhite
        }

        return .levelColor
    }
}
