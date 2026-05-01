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

    override init(defaults: UserDefaults) {
        self.isScreenRecordingLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled
        )
        self.isScreenRecordingDefaultStrokeEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.screenRecordingDefaultStrokeEnabled
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
    }

    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }
}
