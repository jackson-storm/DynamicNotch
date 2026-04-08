import Foundation

enum LockScreenSettings {
    static let liveActivityKey = "isLockScreenLiveActivityEnabled"
    static let mediaPanelKey = "isLockScreenMediaPanelEnabled"
    static let soundKey = "isLockScreenSoundEnabled"
    static let styleKey = "settings.lockScreen.style"
    static let widgetAppearanceStyleKey = "settings.lockScreen.widgetAppearanceStyle"

    static func isLiveActivityEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: liveActivityKey, defaultValue: true, in: defaults)
    }

    static func isMediaPanelEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: mediaPanelKey, defaultValue: true, in: defaults)
    }

    static func isSoundEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: soundKey, defaultValue: true, in: defaults)
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
}
