import Combine
import Foundation
import ServiceManagement

@MainActor
final class ApplicationSettingsStore: SettingsStoreBase, NotchSettingsProviding {
    @Published var isLaunchAtLoginEnabled: Bool {
        didSet {
            persist(isLaunchAtLoginEnabled, for: GeneralSettingsStorage.Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var isDockIconVisible: Bool {
        didSet {
            persist(isDockIconVisible, for: GeneralSettingsStorage.Keys.dockIcon)
        }
    }

    @Published var notchWidth: Int {
        didSet {
            guard oldValue != notchWidth else { return }
            persist(notchWidth, for: GeneralSettingsStorage.Keys.notchWidth)
            notchSizeEvent.send(.width)
        }
    }

    @Published var notchHeight: Int {
        didSet {
            guard oldValue != notchHeight else { return }
            persist(notchHeight, for: GeneralSettingsStorage.Keys.notchHeight)
            notchSizeEvent.send(.height)
        }
    }

    @Published var isMenuBarIconVisible: Bool {
        didSet {
            persist(isMenuBarIconVisible, for: GeneralSettingsStorage.Keys.menuBarIcon)
        }
    }

    @Published var isShowNotchStrokeEnabled: Bool {
        didSet {
            persist(isShowNotchStrokeEnabled, for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        }
    }

    @Published var isDefaultActivityStrokeEnabled: Bool {
        didSet {
            persist(isDefaultActivityStrokeEnabled, for: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled)
        }
    }

    @Published var notchStrokeWidth: Double {
        didSet {
            persist(notchStrokeWidth, for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        }
    }

    @Published var displayLocation: NotchDisplayLocation {
        didSet {
            persist(displayLocation.rawValue, for: GeneralSettingsStorage.Keys.displayLocation)
        }
    }

    @Published var appLanguage: DynamicNotchLanguage {
        didSet {
            persist(appLanguage.rawValue, for: GeneralSettingsStorage.Keys.appLanguage)
        }
    }

    @Published var notchAnimationPreset: NotchAnimationPreset {
        didSet {
            persist(notchAnimationPreset.rawValue, for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        }
    }

    @Published var temporaryActivityDurationScale: Double {
        didSet {
            persist(
                temporaryActivityDurationScale,
                for: GeneralSettingsStorage.Keys.temporaryActivityDurationScale
            )
        }
    }

    @Published var isNotchSizeTemporaryActivityEnabled: Bool {
        didSet {
            persist(
                isNotchSizeTemporaryActivityEnabled,
                for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled
            )
        }
    }

    let notchSizeEvent = PassthroughSubject<NotchSizeEvent, Never>()

    override init(defaults: UserDefaults) {
        self.isLaunchAtLoginEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.launchAtLogin)
        self.isDockIconVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.dockIcon)
        self.notchWidth = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchWidth)
        self.notchHeight = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchHeight)
        self.isMenuBarIconVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.menuBarIcon)
        self.isShowNotchStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        self.isDefaultActivityStrokeEnabled = Self.resolvedDefaultActivityStrokeEnabled(defaults: defaults)
        self.notchStrokeWidth = defaults.double(forKey: GeneralSettingsStorage.Keys.notchStrokeWidth)
        self.displayLocation = NotchDisplayLocation(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue
        ) ?? .main
        self.appLanguage = DynamicNotchLanguage.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.appLanguage)
        )
        self.notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.notchAnimationPreset) ?? NotchAnimationPreset.balanced.rawValue
        ) ?? .balanced
        self.temporaryActivityDurationScale = (
            defaults.object(forKey: GeneralSettingsStorage.Keys.temporaryActivityDurationScale) as? Double
        ) ?? (
            GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.temporaryActivityDurationScale] as? Double ?? 1
        )
        self.isNotchSizeTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        super.init(defaults: defaults)
        updateLaunchAtLogin()
    }

    func resetGeneral() {
        isLaunchAtLoginEnabled = defaultBool(for: GeneralSettingsStorage.Keys.launchAtLogin)
        isDockIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.dockIcon)
        isMenuBarIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.menuBarIcon)
        displayLocation = NotchDisplayLocation(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.displayLocation)
        ) ?? .main
        appLanguage = DynamicNotchLanguage.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appLanguage)
        )
    }

    func resetNotch() {
        notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        ) ?? .balanced
        temporaryActivityDurationScale = defaultDouble(for: GeneralSettingsStorage.Keys.temporaryActivityDurationScale)
        isShowNotchStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        isDefaultActivityStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled)
        isNotchSizeTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        notchStrokeWidth = defaultDouble(for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        notchWidth = defaultInt(for: GeneralSettingsStorage.Keys.notchWidth)
        notchHeight = defaultInt(for: GeneralSettingsStorage.Keys.notchHeight)
    }

    func reset() {
        resetGeneral()
        resetNotch()
    }

    private static func resolvedDefaultActivityStrokeEnabled(defaults: UserDefaults) -> Bool {
        if let currentValue = defaults.object(forKey: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled) as? Bool {
            return currentValue
        }

        let legacyKeys = [
            GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled
        ]

        return legacyKeys.contains { key in
            guard defaults.object(forKey: key) != nil else { return false }
            return defaults.bool(forKey: key)
        }
    }

    private func updateLaunchAtLogin() {
        let instance = SMAppService.mainApp

        do {
            if isLaunchAtLoginEnabled {
                try instance.register()
            } else {
                try instance.unregister()
            }
        } catch {
            print("Ошибка для \(instance.description): \(error)")
        }
    }
}
