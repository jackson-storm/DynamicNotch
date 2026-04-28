import Foundation
import Combine

@MainActor
final class LockScreenFeatureSettingsStore: SettingsStoreBase {
    @Published var isLockScreenLiveActivityEnabled: Bool {
        didSet {
            persist(isLockScreenLiveActivityEnabled, for: LockScreenSettings.liveActivityKey)
        }
    }

    @Published var isLockScreenSoundEnabled: Bool {
        didSet {
            persist(isLockScreenSoundEnabled, for: LockScreenSettings.soundKey)
        }
    }

    @Published var customLockSoundPath: String {
        didSet {
            persist(customLockSoundPath, for: LockScreenSettings.customLockSoundPathKey)
        }
    }

    @Published var customUnlockSoundPath: String {
        didSet {
            persist(customUnlockSoundPath, for: LockScreenSettings.customUnlockSoundPathKey)
        }
    }

    @Published var isLockScreenMediaPanelEnabled: Bool {
        didSet {
            persist(isLockScreenMediaPanelEnabled, for: LockScreenSettings.mediaPanelKey)
        }
    }

    @Published var lockScreenStyle: LockScreenStyle {
        didSet {
            persist(lockScreenStyle.rawValue, for: LockScreenSettings.styleKey)
        }
    }

    @Published var widgetAppearanceStyle: LockScreenWidgetAppearanceStyle {
        didSet {
            persist(widgetAppearanceStyle.rawValue, for: LockScreenSettings.widgetAppearanceStyleKey)
        }
    }

    @Published var widgetTintStyle: LockScreenWidgetTintStyle {
        didSet {
            persist(widgetTintStyle.rawValue, for: LockScreenSettings.widgetTintStyleKey)
        }
    }

    @Published var widgetBackgroundBrightness: Double {
        didSet {
            persist(widgetBackgroundBrightness, for: LockScreenSettings.widgetBackgroundBrightnessKey)
        }
    }

    @Published var mediaPanelBackgroundStyle: LockScreenMediaPanelBackgroundStyle {
        didSet {
            persist(
                mediaPanelBackgroundStyle.rawValue,
                for: LockScreenSettings.mediaPanelBackgroundStyleKey
            )
        }
    }

    override init(defaults: UserDefaults) {
        let legacyCustomSoundPath = LockScreenSettings.legacyCustomSoundPath(in: defaults) ?? ""
        let storedLockSoundPath = defaults.string(forKey: LockScreenSettings.customLockSoundPathKey)
        let storedUnlockSoundPath = defaults.string(forKey: LockScreenSettings.customUnlockSoundPathKey)

        self.isLockScreenLiveActivityEnabled = defaults.bool(forKey: LockScreenSettings.liveActivityKey)
        self.isLockScreenSoundEnabled = defaults.bool(forKey: LockScreenSettings.soundKey)
        self.customLockSoundPath = Self.resolvedCustomSoundPath(
            storedLockSoundPath,
            legacyValue: legacyCustomSoundPath
        )
        self.customUnlockSoundPath = Self.resolvedCustomSoundPath(
            storedUnlockSoundPath,
            legacyValue: legacyCustomSoundPath
        )
        self.isLockScreenMediaPanelEnabled = defaults.bool(forKey: LockScreenSettings.mediaPanelKey)
        self.lockScreenStyle = LockScreenSettings.style(in: defaults)
        self.widgetAppearanceStyle = LockScreenSettings.widgetAppearanceStyle(in: defaults)
        self.widgetTintStyle = LockScreenSettings.widgetTintStyle(in: defaults)
        self.widgetBackgroundBrightness = LockScreenSettings.widgetBackgroundBrightness(in: defaults)
        self.mediaPanelBackgroundStyle = LockScreenSettings.mediaPanelBackgroundStyle(in: defaults)
        super.init(defaults: defaults)

        migrateLegacyCustomSoundIfNeeded(
            legacyCustomSoundPath: legacyCustomSoundPath,
            storedLockSoundPath: storedLockSoundPath,
            storedUnlockSoundPath: storedUnlockSoundPath
        )
    }

    func reset() {
        isLockScreenLiveActivityEnabled = defaultBool(for: LockScreenSettings.liveActivityKey)
        isLockScreenSoundEnabled = defaultBool(for: LockScreenSettings.soundKey)
        customLockSoundPath = defaultString(for: LockScreenSettings.customLockSoundPathKey)
        customUnlockSoundPath = defaultString(for: LockScreenSettings.customUnlockSoundPathKey)
        isLockScreenMediaPanelEnabled = defaultBool(for: LockScreenSettings.mediaPanelKey)
        lockScreenStyle = LockScreenStyle(rawValue: defaultString(for: LockScreenSettings.styleKey)) ?? .compact
        widgetAppearanceStyle = LockScreenWidgetAppearanceStyle(
            rawValue: defaultString(for: LockScreenSettings.widgetAppearanceStyleKey)
        ) ?? .ultraThinMaterial
        widgetTintStyle = LockScreenWidgetTintStyle(
            rawValue: defaultString(for: LockScreenSettings.widgetTintStyleKey)
        ) ?? .neutral
        widgetBackgroundBrightness = defaultDouble(for: LockScreenSettings.widgetBackgroundBrightnessKey)
        mediaPanelBackgroundStyle = LockScreenMediaPanelBackgroundStyle(
            rawValue: defaultString(for: LockScreenSettings.mediaPanelBackgroundStyleKey)
        ) ?? .animatedArtwork
    }

    private static func resolvedCustomSoundPath(_ rawValue: String?, legacyValue: String) -> String {
        let trimmedValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedValue.isEmpty == false {
            return trimmedValue
        }

        return legacyValue
    }

    private func migrateLegacyCustomSoundIfNeeded(
        legacyCustomSoundPath: String,
        storedLockSoundPath: String?,
        storedUnlockSoundPath: String?
    ) {
        guard legacyCustomSoundPath.isEmpty == false else {
            return
        }

        if storedLockSoundPath == nil {
            persist(customLockSoundPath, for: LockScreenSettings.customLockSoundPathKey)
        }

        if storedUnlockSoundPath == nil {
            persist(customUnlockSoundPath, for: LockScreenSettings.customUnlockSoundPathKey)
        }

        persist("", for: LockScreenSettings.customSoundPathKey)
    }
}
