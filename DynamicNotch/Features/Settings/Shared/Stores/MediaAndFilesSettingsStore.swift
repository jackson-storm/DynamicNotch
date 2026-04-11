import Foundation
import Combine

@MainActor
final class MediaAndFilesSettingsStore: SettingsStoreBase {
    @Published var isNowPlayingLiveActivityEnabled: Bool {
        didSet {
            persist(isNowPlayingLiveActivityEnabled, for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        }
    }

    @Published var isNowPlayingFavoriteButtonVisible: Bool {
        didSet {
            persist(isNowPlayingFavoriteButtonVisible, for: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        }
    }

    @Published var isNowPlayingOutputDeviceButtonVisible: Bool {
        didSet {
            persist(isNowPlayingOutputDeviceButtonVisible, for: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        }
    }

    @Published var isNowPlayingArtworkTintEnabled: Bool {
        didSet {
            persist(isNowPlayingArtworkTintEnabled, for: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        }
    }

    @Published var isNowPlayingArtworkStrokeEnabled: Bool {
        didSet {
            persist(isNowPlayingArtworkStrokeEnabled, for: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
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
        self.isNowPlayingFavoriteButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        self.isNowPlayingOutputDeviceButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        self.isNowPlayingArtworkTintEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        self.isNowPlayingArtworkStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
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
        isNowPlayingFavoriteButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        isNowPlayingOutputDeviceButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        isNowPlayingArtworkTintEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        isNowPlayingArtworkStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
    }

    func resetAirDrop() {
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
    }
}

extension MediaAndFilesSettingsStore {
    var nowPlayingAppearanceOptions: NowPlayingAppearanceOptions {
        resolvedNowPlayingAppearanceOptions(isDefaultActivityStrokeEnabled: false)
    }

    func resolvedNowPlayingAppearanceOptions(
        isDefaultActivityStrokeEnabled: Bool
    ) -> NowPlayingAppearanceOptions {
        .init(
            showsFavoriteButton: isNowPlayingFavoriteButtonVisible,
            showsOutputDeviceButton: isNowPlayingOutputDeviceButtonVisible,
            usesArtworkTint: isNowPlayingArtworkTintEnabled,
            usesArtworkStrokeTint: isNowPlayingArtworkStrokeEnabled && !isDefaultActivityStrokeEnabled
        )
    }
}
