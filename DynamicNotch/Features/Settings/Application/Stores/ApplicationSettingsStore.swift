import Combine
import Foundation
internal import AppKit
import ServiceManagement

extension SettingsAppearanceMode: StoredSettingValue {}
extension NotchBackgroundStyle: StoredSettingValue {}
extension NotchDisplayLocation: StoredSettingValue {}
extension DynamicNotchLanguage: StoredSettingValue {}
extension NotchAnimationPreset: StoredSettingValue {}
extension NotchExpandInteraction: StoredSettingValue {}
extension NotchCollapseInteraction: StoredSettingValue {}

@MainActor
final class ApplicationSettingsStore: SettingsStoreBase, NotchSettingsProviding {
    static let notchPressHoldDurationRange: ClosedRange<Double> = 0.20...0.60
    static let notchPressHoldDurationStep: Double = 0.01
    static let defaultNotchPressHoldDuration: TimeInterval = 0.25
    static let notchStrokeWidthRange: ClosedRange<Double> = 1.0...3.0
    static let notchStrokeOpacityRange: ClosedRange<Double> = 0.0...1.0

    @Published var isLaunchAtLoginEnabled: Bool {
        didSet {
            persist(isLaunchAtLoginEnabled, for: GeneralSettingsStorage.Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @StoredDefault(key: GeneralSettingsStorage.Keys.dockIcon, defaultValue: false)
    var isDockIconVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.appearanceMode, defaultValue: .system)
    var appearanceMode: SettingsAppearanceMode

    @StoredDefault(key: GeneralSettingsStorage.Keys.isBlueNightMode, defaultValue: false)
    var isBlueNightMode: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchBackgroundStyle, defaultValue: .black)
    var notchBackgroundStyle: NotchBackgroundStyle

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

    @StoredDefault(key: GeneralSettingsStorage.Keys.menuBarIcon, defaultValue: true)
    var isMenuBarIconVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchStrokeEnabled, defaultValue: false)
    var isShowNotchStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled, defaultValue: true)
    var isDefaultActivityStrokeEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.notchStrokeWidth,
        defaultValue: 1.5,
        transform: ApplicationSettingsStore.clampNotchStrokeWidth
    )
    var notchStrokeWidth: Double

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.notchStrokeOpacity,
        defaultValue: 1.0,
        transform: ApplicationSettingsStore.clampNotchStrokeOpacity
    )
    var notchStrokeOpacity: Double

    @Published var displayLocation: NotchDisplayLocation {
        didSet {
            persist(displayLocation.rawValue, for: GeneralSettingsStorage.Keys.displayLocation)

            if displayLocation == .specific {
                ensureSpecificDisplaySelection(previousLocation: oldValue)
            }
        }
    }

    @StoredDefault(key: GeneralSettingsStorage.Keys.preferredDisplayUUID, defaultValue: "")
    var preferredDisplayUUID: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.preferredDisplayName, defaultValue: "")
    var preferredDisplayName: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.displayAutoSwitchEnabled, defaultValue: true)
    var isDisplayAutoSwitchEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.appLanguage, defaultValue: .system)
    var appLanguage: DynamicNotchLanguage

    @StoredDefault(key: GeneralSettingsStorage.Keys.hideNotchInFullscreenEnabled, defaultValue: false)
    var isNotchHiddenInFullscreenEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchAnimationPreset, defaultValue: .balanced)
    var notchAnimationPreset: NotchAnimationPreset

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchTapToExpandEnabled, defaultValue: true)
    var isNotchTapToExpandEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchExpandInteraction, defaultValue: .hover)
    var notchExpandInteraction: NotchExpandInteraction

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchCollapseInteraction, defaultValue: .click)
    var notchCollapseInteraction: NotchCollapseInteraction

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.notchPressHoldDuration,
        defaultValue: 0.25,
        transform: ApplicationSettingsStore.clampNotchPressHoldDuration
    )
    var notchPressHoldDuration: TimeInterval

    var isNotchMouseDragGesturesEnabled: Bool {
        get { true }
        set {}
    }

    var isNotchTrackpadSwipeGesturesEnabled: Bool {
        get { true }
        set {}
    }

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchSwipeDismissEnabled, defaultValue: true)
    var isNotchSwipeDismissEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchSwipeRestoreEnabled, defaultValue: true)
    var isNotchSwipeRestoreEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchHoverHapticEnabled, defaultValue: true)
    var isNotchHoverHapticEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.closeAtFocusLiveActivityEnabled, defaultValue: false)
    var isCloseAtFocusLiveActivityEnabled: Bool

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

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled, defaultValue: true)
    var isNotchSizeTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration,
        defaultValue: 2,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var notchSizeTemporaryActivityDuration: Int

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
        self.notchWidth = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchWidth)
        self.notchHeight = defaults.integer(forKey: GeneralSettingsStorage.Keys.notchHeight)
        self.displayLocation = NotchDisplayLocation(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.displayLocation) ?? NotchDisplayLocation.main.rawValue
        ) ?? .main
        self.notchContentPriorityOverrides = NotchContentPriority.overrideValues(defaults: defaults)

        super.init(defaults: defaults)
        persistSanitizedNotchStrokeSettingsIfNeeded()
        ensureSpecificDisplaySelection(previousLocation: .main)
        updateLaunchAtLogin()
    }

    func resetGeneral() {
        isLaunchAtLoginEnabled = defaultBool(for: GeneralSettingsStorage.Keys.launchAtLogin)
        isDockIconVisible = defaultBool(for: GeneralSettingsStorage.Keys.dockIcon)
        appearanceMode = SettingsAppearanceMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appearanceMode)
        )

        isBlueNightMode = defaultBool(for: GeneralSettingsStorage.Keys.isBlueNightMode)
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

    func resetAppearance() {
        appearanceMode = SettingsAppearanceMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appearanceMode)
        )
        isBlueNightMode = defaultBool(for: GeneralSettingsStorage.Keys.isBlueNightMode)
    }

    func resetDisplay() {
        displayLocation = NotchDisplayLocation(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.displayLocation)
        ) ?? .main
        preferredDisplayUUID = defaultString(for: GeneralSettingsStorage.Keys.preferredDisplayUUID)
        preferredDisplayName = defaultString(for: GeneralSettingsStorage.Keys.preferredDisplayName)
        isDisplayAutoSwitchEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.displayAutoSwitchEnabled
        )
        isNotchHiddenInFullscreenEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.hideNotchInFullscreenEnabled
        )
    }

    func resetLanguage() {
        appLanguage = DynamicNotchLanguage.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.appLanguage)
        )
    }

    func resetAnimation() {
        notchAnimationPreset = NotchAnimationPreset(
            rawValue: defaultString(for: GeneralSettingsStorage.Keys.notchAnimationPreset)
        ) ?? .balanced
    }

    func resetGestures() {
        isNotchTapToExpandEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchTapToExpandEnabled)
        notchExpandInteraction = NotchExpandInteraction.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.notchExpandInteraction)
        )
        notchCollapseInteraction = NotchCollapseInteraction.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.notchCollapseInteraction)
        )
        notchPressHoldDuration = Self.clampNotchPressHoldDuration(
            defaultDouble(for: GeneralSettingsStorage.Keys.notchPressHoldDuration)
        )
        isNotchSwipeDismissEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSwipeDismissEnabled)
        isNotchSwipeRestoreEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSwipeRestoreEnabled)
        isNotchHoverHapticEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchHoverHapticEnabled)
        isCloseAtFocusLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.closeAtFocusLiveActivityEnabled)
    }

    func resetNotch() {
        resetAnimation()
        resetGestures()
        resetNotchContentPriorities()
        isShowNotchStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchStrokeEnabled)
        isDefaultActivityStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.defaultActivityStrokeEnabled)
        isNotchSizeTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityEnabled)
        notchSizeTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.notchSizeTemporaryActivityDuration)
        )
        notchStrokeWidth = defaultDouble(for: GeneralSettingsStorage.Keys.notchStrokeWidth)
        notchStrokeOpacity = defaultDouble(for: GeneralSettingsStorage.Keys.notchStrokeOpacity)
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

    private static func resolvedNotchStrokeWidth(defaults: UserDefaults) -> Double {
        let key = GeneralSettingsStorage.Keys.notchStrokeWidth

        guard let currentValue = (defaults.object(forKey: key) as? NSNumber)?.doubleValue else {
            return defaultDoubleValue(for: key)
        }

        return clampNotchStrokeWidth(currentValue)
    }



    private static func defaultDoubleValue(for key: String) -> Double {
        (GeneralSettingsStorage.defaultValues[key] as? Double) ?? 0
    }

    static func clampNotchStrokeWidth(_ value: Double) -> Double {
        min(
            max(value, notchStrokeWidthRange.lowerBound),
            notchStrokeWidthRange.upperBound
        )
    }

    static func clampNotchStrokeOpacity(_ value: Double) -> Double {
        min(
            max(value, notchStrokeOpacityRange.lowerBound),
            notchStrokeOpacityRange.upperBound
        )
    }

    private static func resolvedNotchStrokeOpacity(defaults: UserDefaults) -> Double {
        let key = GeneralSettingsStorage.Keys.notchStrokeOpacity

        guard let currentValue = (defaults.object(forKey: key) as? NSNumber)?.doubleValue else {
            return defaultDoubleValue(for: key)
        }

        return clampNotchStrokeOpacity(currentValue)
    }



    private func persistSanitizedNotchStrokeSettingsIfNeeded() {
        let key = GeneralSettingsStorage.Keys.notchStrokeWidth
        if let storedValue = (defaults.object(forKey: key) as? NSNumber)?.doubleValue {
            let clampedValue = Self.clampNotchStrokeWidth(storedValue)
            if clampedValue != storedValue {
                persist(clampedValue, for: key)
            }
        }

        let opacityKey = GeneralSettingsStorage.Keys.notchStrokeOpacity
        if let storedOpacity = (defaults.object(forKey: opacityKey) as? NSNumber)?.doubleValue {
            let clampedOpacity = Self.clampNotchStrokeOpacity(storedOpacity)
            if clampedOpacity != storedOpacity {
                persist(clampedOpacity, for: opacityKey)
            }
        }


    }

    static func clampNotchPressHoldDuration(_ value: TimeInterval) -> TimeInterval {
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
