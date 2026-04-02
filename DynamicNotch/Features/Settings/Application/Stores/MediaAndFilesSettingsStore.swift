import Foundation
import Combine

@MainActor
final class MediaAndFilesSettingsStore: SettingsStoreBase {
    @Published var isNowPlayingLiveActivityEnabled: Bool {
        didSet {
            persist(isNowPlayingLiveActivityEnabled, for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        }
    }

    @Published var isDownloadsLiveActivityEnabled: Bool {
        didSet {
            persist(isDownloadsLiveActivityEnabled, for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        }
    }

    @Published var isAirDropLiveActivityEnabled: Bool {
        didSet {
            persist(isAirDropLiveActivityEnabled, for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        let hasLegacyDownloadsValue = defaults.object(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) != nil
        let downloadsSettingValue = defaults.object(forKey: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled) as? Bool
        self.isDownloadsLiveActivityEnabled = downloadsSettingValue ?? (
            hasLegacyDownloadsValue ?
            defaults.bool(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) :
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled] as? Bool ?? true)
        )
        self.isAirDropLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        super.init(defaults: defaults)
    }

    func resetNowPlaying() {
        isNowPlayingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
    }

    func resetAirDrop() {
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
    }
}
