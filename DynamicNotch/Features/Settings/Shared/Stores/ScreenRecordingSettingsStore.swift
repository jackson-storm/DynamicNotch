import Combine
import Foundation

@MainActor
final class ScreenRecordingSettingsStore: SettingsStoreBase {
    @Published var isScreenRecordingLiveActivityEnabled: Bool {
        didSet {
            persist(
                isScreenRecordingLiveActivityEnabled,
                for: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled
            )
        }
    }

    @Published var isScreenRecordingDefaultStrokeEnabled: Bool {
        didSet {
            persist(
                isScreenRecordingDefaultStrokeEnabled,
                for: GeneralSettingsStorage.Keys.screenRecordingDefaultStrokeEnabled
            )
        }
    }

    @Published var isScreenshotActivityEnabled: Bool {
        didSet {
            persist(
                isScreenshotActivityEnabled,
                for: GeneralSettingsStorage.Keys.screenshotActivityEnabled
            )
        }
    }

    @Published var isScreenshotDisableSystemThumbnailEnabled: Bool {
        didSet {
            persist(
                isScreenshotDisableSystemThumbnailEnabled,
                for: GeneralSettingsStorage.Keys.screenshotDisableSystemThumbnail
            )
        }
    }

    @Published var isScreenshotAutoHideEnabled: Bool {
        didSet {
            persist(
                isScreenshotAutoHideEnabled,
                for: GeneralSettingsStorage.Keys.screenshotAutoHideEnabled
            )
        }
    }

    @Published var screenshotTemporaryActivityDuration: Int {
        didSet {
            persist(
                screenshotTemporaryActivityDuration,
                for: GeneralSettingsStorage.Keys.screenshotTemporaryActivityDuration
            )
        }
    }

    @Published var screenshotSavePath: String {
        didSet {
            persist(
                screenshotSavePath,
                for: GeneralSettingsStorage.Keys.screenshotSavePath
            )
        }
    }

    @Published var screenRecordingSavePath: String {
        didSet {
            persist(
                screenRecordingSavePath,
                for: GeneralSettingsStorage.Keys.screenRecordingSavePath
            )
        }
    }

    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isScreenRecordingLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled
        )
        self.isScreenRecordingDefaultStrokeEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenRecordingDefaultStrokeEnabled
        )
        self.isScreenshotActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenshotActivityEnabled
        )
        self.isScreenshotDisableSystemThumbnailEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenshotDisableSystemThumbnail
        )
        self.isScreenshotAutoHideEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenshotAutoHideEnabled
        )
        self.screenshotTemporaryActivityDuration = Self.resolvedInt(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenshotTemporaryActivityDuration
        )
        self.screenshotSavePath = Self.resolvedString(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenshotSavePath
        )
        self.screenRecordingSavePath = Self.resolvedString(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenRecordingSavePath
        )
        super.init(defaults: defaults)
    }

    func reset() {
        isScreenRecordingLiveActivityEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled
        )
        isScreenRecordingDefaultStrokeEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.screenRecordingDefaultStrokeEnabled
        )
        isScreenshotActivityEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.screenshotActivityEnabled
        )
        isScreenshotDisableSystemThumbnailEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.screenshotDisableSystemThumbnail
        )
        isScreenshotAutoHideEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.screenshotAutoHideEnabled
        )
        screenshotTemporaryActivityDuration = defaultInt(
            for: GeneralSettingsStorage.Keys.screenshotTemporaryActivityDuration
        )
        screenshotSavePath = defaultString(
            for: GeneralSettingsStorage.Keys.screenshotSavePath
        )
        screenRecordingSavePath = defaultString(
            for: GeneralSettingsStorage.Keys.screenRecordingSavePath
        )
    }

    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }

    private static func resolvedInt(defaults: UserDefaults, key: String) -> Int {
        if let currentValue = defaults.object(forKey: key) as? Int {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Int) ?? 4
    }

    private static func resolvedString(defaults: UserDefaults, key: String) -> String {
        if let currentValue = defaults.object(forKey: key) as? String {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? String) ?? ""
    }
}
