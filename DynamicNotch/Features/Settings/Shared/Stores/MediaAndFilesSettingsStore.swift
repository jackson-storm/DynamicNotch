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

    @Published var nowPlayingEqualizerMode: NowPlayingEqualizerMode {
        didSet {
            persist(nowPlayingEqualizerMode.rawValue, for: GeneralSettingsStorage.Keys.nowPlayingEqualizerMode)
        }
    }

    @Published var isDownloadsLiveActivityEnabled: Bool {
        didSet {
            persist(isDownloadsLiveActivityEnabled, for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        }
    }

    @Published var isDownloadsDefaultStrokeEnabled: Bool {
        didSet {
            persist(isDownloadsDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        }
    }

    @Published var downloadsAppearanceStyle: DownloadAppearanceStyle {
        didSet {
            persist(downloadsAppearanceStyle.rawValue, for: GeneralSettingsStorage.Keys.downloadsAppearanceStyle)
        }
    }

    @Published var downloadsProgressIndicatorStyle: DownloadProgressIndicatorStyle {
        didSet {
            persist(
                downloadsProgressIndicatorStyle.rawValue,
                for: GeneralSettingsStorage.Keys.downloadsProgressIndicatorStyle
            )
        }
    }

    @Published var isAirDropLiveActivityEnabled: Bool {
        didSet {
            persist(isAirDropLiveActivityEnabled, for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        }
    }

    @Published var isAirDropDefaultStrokeEnabled: Bool {
        didSet {
            persist(isAirDropDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        self.isNowPlayingFavoriteButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        self.isNowPlayingOutputDeviceButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        self.isNowPlayingArtworkTintEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        self.isNowPlayingArtworkStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
        self.nowPlayingEqualizerMode = NowPlayingEqualizerMode.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.nowPlayingEqualizerMode)
        )
        let hasLegacyDownloadsValue = defaults.object(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) != nil
        let downloadsSettingValue = defaults.object(forKey: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled) as? Bool
        self.isDownloadsLiveActivityEnabled = downloadsSettingValue ?? (
            hasLegacyDownloadsValue ?
            defaults.bool(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) :
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled] as? Bool ?? true)
        )
        self.isDownloadsDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        self.downloadsAppearanceStyle = DownloadAppearanceStyle.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.downloadsAppearanceStyle)
        )
        self.downloadsProgressIndicatorStyle = DownloadProgressIndicatorStyle.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.downloadsProgressIndicatorStyle)
        )
        self.isAirDropLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        self.isAirDropDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func resetNowPlaying() {
        isNowPlayingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        isNowPlayingFavoriteButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        isNowPlayingOutputDeviceButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        isNowPlayingArtworkTintEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        isNowPlayingArtworkStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
        nowPlayingEqualizerMode = NowPlayingEqualizerMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.nowPlayingEqualizerMode)
        )
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        isDownloadsDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        downloadsAppearanceStyle = DownloadAppearanceStyle.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.downloadsAppearanceStyle)
        )
        downloadsProgressIndicatorStyle = DownloadProgressIndicatorStyle.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.downloadsProgressIndicatorStyle)
        )
    }

    func resetAirDrop() {
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        isAirDropDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
    }
}

struct NowPlayingAppearanceOptions {
    let showsFavoriteButton: Bool
    let showsOutputDeviceButton: Bool
    let usesArtworkTint: Bool
    let usesArtworkStrokeTint: Bool
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
