import Combine
import Foundation
internal import AppKit
import ServiceManagement

@MainActor
final class ApplicationSettingsStore: SettingsStoreBase, NotchSettingsProviding {
    static let notchPressHoldDurationRange: ClosedRange<Double> = 0.20...0.60
    static let notchPressHoldDurationStep: Double = 0.01
    static let defaultNotchPressHoldDuration: TimeInterval = 0.25

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

    @Published var appearanceMode: SettingsAppearanceMode {
        didSet {
            persist(appearanceMode.rawValue, for: GeneralSettingsStorage.Keys.appearanceMode)
        }
    }

    @Published var notchBackgroundStyle: NotchBackgroundStyle {
        didSet {
            persist(notchBackgroundStyle.rawValue, for: GeneralSettingsStorage.Keys.notchBackgroundStyle)
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

            if displayLocation == .specific {
                ensureSpecificDisplaySelection(previousLocation: oldValue)
            }
        }
    }

    @Published var preferredDisplayUUID: String {
        didSet {
            persist(preferredDisplayUUID, for: GeneralSettingsStorage.Keys.preferredDisplayUUID)
        }
    }

    @Published var preferredDisplayName: String {
        didSet {
            persist(preferredDisplayName, for: GeneralSettingsStorage.Keys.preferredDisplayName)
        }
    }

    @Published var isDisplayAutoSwitchEnabled: Bool {
        didSet {
            persist(
                isDisplayAutoSwitchEnabled,
                for: GeneralSettingsStorage.Keys.displayAutoSwitchEnabled
            )
        }
    }

    @Published var appLanguage: DynamicNotchLanguage {
        didSet {
            persist(appLanguage.rawValue, for: GeneralSettingsStorage.Keys.appLanguage)
        }
    }

    @Published var isNotchHiddenInFullscreenEnabled: Bool {
        didSet {
            persist(
                isNotchHiddenInFullscreenEnabled,
                for: GeneralSettingsStorage.Keys.hideNotchInFullscreenEnabled
            )
        }
    }

    @Published var notchAnimationPreset: NotchAnimationPreset {
        didSet {
            persist(notchAnimationPreset.rawValue, for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        }
    }

    @Published var isNotchTapToExpandEnabled: Bool {
        didSet {
            persist(isNotchTapToExpandEnabled, for: GeneralSettingsStorage.Keys.notchTapToExpandEnabled)
        }
    }

    @Published var notchExpandInteraction: NotchExpandInteraction {
        didSet {
            persist(notchExpandInteraction.rawValue, for: GeneralSettingsStorage.Keys.notchExpandInteraction)
        }
    }

    @Published var notchPressHoldDuration: TimeInterval {
        didSet {
            let clampedValue = Self.clampNotchPressHoldDuration(notchPressHoldDuration)

            if clampedValue != notchPressHoldDuration {
                notchPressHoldDuration = clampedValue
                return
            }

            persist(notchPressHoldDuration, for: GeneralSettingsStorage.Keys.notchPressHoldDuration)
        }
    }

    @Published var isNotchMouseDragGesturesEnabled: Bool {
        didSet {
            persist(
                isNotchMouseDragGesturesEnabled,
                for: GeneralSettingsStorage.Keys.notchMouseDragGesturesEnabled
            )
        }
    }

    @Published var isNotchTrackpadSwipeGesturesEnabled: Bool {
        didSet {
            persist(
                isNotchTrackpadSwipeGesturesEnabled,
                for: GeneralSettingsStorage.Keys.notchTrackpadSwipeGesturesEnabled
            )
        }
    }

    @Published var isNotchSwipeDismissEnabled: Bool {
        didSet {
            persist(isNotchSwipeDismissEnabled, for: GeneralSettingsStorage.Keys.notchSwipeDismissEnabled)
        }
    }

    @Published var isNotchSwipeRestoreEnabled: Bool {
        didSet {
            persist(isNotchSwipeRestoreEnabled, for: GeneralSettingsStorage.Keys.notchSwipeRestoreEnabled)
        }
    }

    @Published var notchContentPriorityOverrides: [String: Int] {
        didSet {
            let sanitizedOverrides = NotchContentPriority.sanitizedOverrides(notchContentPriorityOverrides)

            guard sanitizedOverrides == notchContentPriorityOverrides else {
                notchContentPriorityOverrides = sanitizedOverrides
                return
            }

            persist(
                notchContentPriorityOverrides,
                for: GeneralSettingsStorage.Keys.notchContentPriorityOverrides
            )
            NotificationCenter.default.post(name: .notchContentPrioritiesDidChange, object: self)
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

    @Published var notchSizeTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(notchSizeTemporaryActivityDuration)
            if clampedValue != notchSizeTemporaryActivityDuration {
                notchSizeTemporaryActivityDuration = clampedValue
                return
            }

            persist(
                notchSizeTemporaryActivityDuration,
                for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration
            )
        }
    }

    let notchSizeEvent = PassthroughSubject<NotchSizeEvent, Never>()

    var screenSelectionPreferences: NotchScreenSelectionPreferences {
        NotchScreenSelectionPreferences(
            displayLocation: displayLocation,
            preferredDisplayUUID: preferredDisplayUUID.isEmpty ? nil : preferredDisplayUUID,
            allowsAutomaticDisplaySwitching: isDisplayAutoSwitchEnabled
        )
    }

    override init(defaults: UserDefaults) {
        self.isLaunchAtLoginEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.launchAtLogin)
        self.isDockIconVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.dockIcon)
        self.appearanceMode = SettingsAppearanceMode.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.appearanceMode)
        )
        self.notchBackgroundStyle = NotchBackgroundStyle.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.notchBackgroundStyle)
        )
        self.notchWidth = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchWidth)
        self.notchHeight = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchHeight)
        self.isMenuBarIconVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.menuBarIcon)
        self.isShowNotchStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        self.isDefaultActivityStrokeEnabled = Self.resolvedDefaultActivityStrokeEnabled(defaults: defaults)
        self.notchStrokeWidth = defaults.double(forKey: GeneralSettingsStorage.Keys.notchStrokeWidth)
        self.displayLocation = NotchDisplayLocation(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue
        ) ?? .main
        self.preferredDisplayUUID = defaults.string(
            forKey: GeneralSettingsStorage.Keys.preferredDisplayUUID
        ) ?? ""
        self.preferredDisplayName = defaults.string(
            forKey: GeneralSettingsStorage.Keys.preferredDisplayName
        ) ?? ""
        self.isDisplayAutoSwitchEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.displayAutoSwitchEnabled
        )
        self.appLanguage = DynamicNotchLanguage.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.appLanguage)
        )
        self.isNotchHiddenInFullscreenEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.hideNotchInFullscreenEnabled
        )
        self.notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.notchAnimationPreset) ?? NotchAnimationPreset.balanced.rawValue
        ) ?? .balanced
        self.isNotchTapToExpandEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.notchTapToExpandEnabled
        )
        self.notchExpandInteraction = NotchExpandInteraction.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.notchExpandInteraction)
        )
        self.notchPressHoldDuration = Self.clampNotchPressHoldDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.notchPressHoldDuration) as? Double ??
            Self.defaultNotchPressHoldDuration
        )
        self.isNotchMouseDragGesturesEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.notchMouseDragGesturesEnabled
        )
        self.isNotchTrackpadSwipeGesturesEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.notchTrackpadSwipeGesturesEnabled
        )
        self.isNotchSwipeDismissEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.notchSwipeDismissEnabled
        )
        self.isNotchSwipeRestoreEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.notchSwipeRestoreEnabled
        )
        self.notchContentPriorityOverrides = NotchContentPriority.overrideValues(defaults: defaults)
        self.isNotchSizeTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        self.notchSizeTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration)
        )
        super.init(defaults: defaults)
        ensureSpecificDisplaySelection(previousLocation: .main)
        updateLaunchAtLogin()
    }

    func resetGeneral() {
        isLaunchAtLoginEnabled = defaultBool(for: GeneralSettingsStorage.Keys.launchAtLogin)
        isDockIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.dockIcon)
        appearanceMode = SettingsAppearanceMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appearanceMode)
        )
        isMenuBarIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.menuBarIcon)
        displayLocation = NotchDisplayLocation(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.displayLocation)
        ) ?? .main
        preferredDisplayUUID = defaultString(for: GeneralSettingsStorage.Keys.preferredDisplayUUID)
        preferredDisplayName = defaultString(for: GeneralSettingsStorage.Keys.preferredDisplayName)
        isDisplayAutoSwitchEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.displayAutoSwitchEnabled
        )
        appLanguage = DynamicNotchLanguage.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appLanguage)
        )
        isNotchHiddenInFullscreenEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.hideNotchInFullscreenEnabled
        )
    }

    func resetNotch() {
        notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        ) ?? .balanced
        isNotchTapToExpandEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchTapToExpandEnabled)
        notchExpandInteraction = NotchExpandInteraction.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.notchExpandInteraction)
        )
        notchPressHoldDuration = Self.clampNotchPressHoldDuration(
            defaultDouble(for: GeneralSettingsStorage.Keys.notchPressHoldDuration)
        )
        isNotchMouseDragGesturesEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchMouseDragGesturesEnabled)
        isNotchTrackpadSwipeGesturesEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchTrackpadSwipeGesturesEnabled)
        isNotchSwipeDismissEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSwipeDismissEnabled)
        isNotchSwipeRestoreEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSwipeRestoreEnabled)
        resetNotchContentPriorities()
        isShowNotchStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        isDefaultActivityStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled)
        isNotchSizeTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        notchSizeTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration)
        )
        notchStrokeWidth = defaultDouble(for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        notchBackgroundStyle = NotchBackgroundStyle.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.notchBackgroundStyle)
        )
        notchWidth = defaultInt(for: GeneralSettingsStorage.Keys.notchWidth)
        notchHeight = defaultInt(for: GeneralSettingsStorage.Keys.notchHeight)
    }

    func reset() {
        resetGeneral()
        resetNotch()
    }

    func notchContentPriority(for key: NotchContentPriority.Key) -> Int {
        notchContentPriorityOverrides[key.rawValue] ?? key.defaultValue
    }

    func setNotchContentPriority(_ priority: Int, for key: NotchContentPriority.Key) {
        let clampedPriority = NotchContentPriority.clamped(priority)
        var overrides = notchContentPriorityOverrides

        if clampedPriority == key.defaultValue {
            overrides.removeValue(forKey: key.rawValue)
        } else {
            overrides[key.rawValue] = clampedPriority
        }

        notchContentPriorityOverrides = overrides
    }

    func resetNotchContentPriorities() {
        notchContentPriorityOverrides = [:]
    }

    private static func resolvedDefaultActivityStrokeEnabled(defaults: UserDefaults) -> Bool {
        if let currentValue = defaults.object(forKey: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled) as? Bool {
            return currentValue
        }

        let legacyKeys = [
            GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.focusDefaultStrokeEnabled,
            GeneralSettingsStorage.Keys.hotspotDefaultStrokeEnabled
        ]

        return legacyKeys.contains { key in
            guard defaults.object(forKey: key) != nil else { return false }
            return defaults.bool(forKey: key)
        }
    }

    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }

    private static func clampNotchPressHoldDuration(_ value: TimeInterval) -> TimeInterval {
        min(
            max(value, notchPressHoldDurationRange.lowerBound),
            notchPressHoldDurationRange.upperBound
        )
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

    func selectPreferredDisplay(_ display: NotchDisplayOption) {
        guard display.isAvailable else { return }

        preferredDisplayUUID = display.displayUUID
        preferredDisplayName = display.name
    }

    func syncPreferredDisplayMetadata() {
        guard !preferredDisplayUUID.isEmpty,
              let selectedDisplay = NSScreen.availableNotchDisplays().first(where: {
                  $0.displayUUID == preferredDisplayUUID
              })
        else {
            return
        }

        if preferredDisplayName != selectedDisplay.name {
            preferredDisplayName = selectedDisplay.name
        }
    }

    private func ensureSpecificDisplaySelection(previousLocation: NotchDisplayLocation) {
        guard displayLocation == .specific else { return }

        if !preferredDisplayUUID.isEmpty {
            syncPreferredDisplayMetadata()
            return
        }

        let previousPreferences = NotchScreenSelectionPreferences(
            displayLocation: previousLocation,
            preferredDisplayUUID: preferredDisplayUUID.isEmpty ? nil : preferredDisplayUUID,
            allowsAutomaticDisplaySwitching: isDisplayAutoSwitchEnabled
        )

        if let resolvedDisplay = NSScreen.preferredNotchDisplay(for: previousPreferences) ??
            NSScreen.availableNotchDisplays().first {
            selectPreferredDisplay(resolvedDisplay)
        }
    }
}
