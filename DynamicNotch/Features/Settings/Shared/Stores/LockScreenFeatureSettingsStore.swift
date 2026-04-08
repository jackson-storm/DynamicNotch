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

    override init(defaults: UserDefaults) {
        self.isLockScreenLiveActivityEnabled = defaults.bool(forKey: LockScreenSettings.liveActivityKey)
        self.isLockScreenSoundEnabled = defaults.bool(forKey: LockScreenSettings.soundKey)
        self.isLockScreenMediaPanelEnabled = defaults.bool(forKey: LockScreenSettings.mediaPanelKey)
        self.lockScreenStyle = LockScreenSettings.style(in: defaults)
        self.widgetAppearanceStyle = LockScreenSettings.widgetAppearanceStyle(in: defaults)
        super.init(defaults: defaults)
    }

    func reset() {
        isLockScreenLiveActivityEnabled = defaultBool(for: LockScreenSettings.liveActivityKey)
        isLockScreenSoundEnabled = defaultBool(for: LockScreenSettings.soundKey)
        isLockScreenMediaPanelEnabled = defaultBool(for: LockScreenSettings.mediaPanelKey)
        lockScreenStyle = LockScreenStyle(rawValue: defaultString(for: LockScreenSettings.styleKey)) ?? .compact
        widgetAppearanceStyle = LockScreenWidgetAppearanceStyle(
            rawValue: defaultString(for: LockScreenSettings.widgetAppearanceStyleKey)
        ) ?? .ultraThinMaterial
    }
}
