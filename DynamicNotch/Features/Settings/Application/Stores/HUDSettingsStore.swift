import Foundation
import Combine

@MainActor
final class HUDSettingsStore: SettingsStoreBase {
    @Published var isBrightnessHUDEnabled: Bool {
        didSet {
            persist(isBrightnessHUDEnabled, for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        }
    }

    @Published var isKeyboardHUDEnabled: Bool {
        didSet {
            persist(isKeyboardHUDEnabled, for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        }
    }

    @Published var isVolumeHUDEnabled: Bool {
        didSet {
            persist(isVolumeHUDEnabled, for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isBrightnessHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        self.isKeyboardHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        self.isVolumeHUDEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isBrightnessHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        isKeyboardHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        isVolumeHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
    }
}
