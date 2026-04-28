import Foundation

enum LockScreenSettings {
    static let liveActivityKey = "isLockScreenLiveActivityEnabled"
    static let mediaPanelKey = "isLockScreenMediaPanelEnabled"
    static let soundKey = "isLockScreenSoundEnabled"
    static let customSoundPathKey = "settings.lockScreen.customSoundPath"
    static let customLockSoundPathKey = "settings.lockScreen.customLockSoundPath"
    static let customUnlockSoundPathKey = "settings.lockScreen.customUnlockSoundPath"
    static let styleKey = "settings.lockScreen.style"
    static let widgetAppearanceStyleKey = "settings.lockScreen.widgetAppearanceStyle"
    static let widgetTintStyleKey = "settings.lockScreen.widgetTintStyle"
    static let widgetBackgroundBrightnessKey = "settings.lockScreen.widgetBackgroundBrightness"
    static let mediaPanelBackgroundStyleKey = "settings.lockScreen.mediaPanelBackgroundStyle"
    static let widgetBackgroundBrightnessRange = 0.75...1.25

    static func isLiveActivityEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: liveActivityKey, defaultValue: true, in: defaults)
    }

    static func isMediaPanelEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: mediaPanelKey, defaultValue: true, in: defaults)
    }

    static func isSoundEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: soundKey, defaultValue: true, in: defaults)
    }

    static func legacyCustomSoundPath(in defaults: UserDefaults = .standard) -> String? {
        resolvedPath(forKey: customSoundPathKey, in: defaults)
    }

    static func customLockSoundPath(in defaults: UserDefaults = .standard) -> String? {
        resolvedPath(forKey: customLockSoundPathKey, in: defaults)
    }

    static func customUnlockSoundPath(in defaults: UserDefaults = .standard) -> String? {
        resolvedPath(forKey: customUnlockSoundPathKey, in: defaults)
    }

    static func style(in defaults: UserDefaults = .standard) -> LockScreenStyle {
        guard
            let rawValue = defaults.string(forKey: styleKey),
            let style = LockScreenStyle(rawValue: rawValue)
        else {
            return .compact
        }

        return style
    }

    static func widgetAppearanceStyle(in defaults: UserDefaults = .standard) -> LockScreenWidgetAppearanceStyle {
        guard
            let rawValue = defaults.string(forKey: widgetAppearanceStyleKey),
            let style = LockScreenWidgetAppearanceStyle(rawValue: rawValue)
        else {
            return .ultraThinMaterial
        }

        guard style.isSupportedOnCurrentSystem else {
            return .ultraThinMaterial
        }

        return style
    }

    static func widgetTintStyle(in defaults: UserDefaults = .standard) -> LockScreenWidgetTintStyle {
        guard
            let rawValue = defaults.string(forKey: widgetTintStyleKey),
            let tintStyle = LockScreenWidgetTintStyle(rawValue: rawValue)
        else {
            return .neutral
        }

        return tintStyle
    }

    static func widgetBackgroundBrightness(in defaults: UserDefaults = .standard) -> Double {
        guard let value = defaults.object(forKey: widgetBackgroundBrightnessKey) as? Double else {
            return 1.0
        }

        return min(max(value, widgetBackgroundBrightnessRange.lowerBound), widgetBackgroundBrightnessRange.upperBound)
    }

    static func mediaPanelBackgroundStyle(in defaults: UserDefaults = .standard) -> LockScreenMediaPanelBackgroundStyle {
        guard
            let rawValue = defaults.string(forKey: mediaPanelBackgroundStyleKey),
            let style = LockScreenMediaPanelBackgroundStyle(rawValue: rawValue)
        else {
            return .animatedArtwork
        }
        return style
    }

    private static func resolvedBoolean(
        forKey key: String,
        defaultValue: Bool,
        in defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: key)
    }

    private static func resolvedPath(forKey key: String, in defaults: UserDefaults) -> String? {
        guard let rawValue = defaults.string(forKey: key) else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false else {
            return nil
        }

        return trimmedValue
    }
}
