import Foundation

enum LockScreenSettings {
    static let liveActivityKey = "isLockScreenLiveActivityEnabled"
    static let mediaPanelKey = "isLockScreenMediaPanelEnabled"
    static let soundKey = "isLockScreenSoundEnabled"

    static func isLiveActivityEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: liveActivityKey, defaultValue: true, in: defaults)
    }

    static func isMediaPanelEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: mediaPanelKey, defaultValue: true, in: defaults)
    }

    static func isSoundEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: soundKey, defaultValue: true, in: defaults)
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
