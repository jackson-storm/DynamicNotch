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

    @Published var isNowPlayingPauseHideTimerEnabled: Bool {
        didSet {
            persist(
                isNowPlayingPauseHideTimerEnabled,
                for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled
            )
        }
    }

    @Published var nowPlayingPauseHideDelay: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(nowPlayingPauseHideDelay)
            if clampedValue != nowPlayingPauseHideDelay {
                nowPlayingPauseHideDelay = clampedValue
                return
            }

            persist(nowPlayingPauseHideDelay, for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
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

    @Published var isDragAndDropLiveActivityEnabled: Bool {
        didSet {
            persist(isDragAndDropLiveActivityEnabled, for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        }
    }

    @Published var isDragAndDropDefaultStrokeEnabled: Bool {
        didSet {
            persist(isDragAndDropDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        }
    }
    
    @Published var isDropMotionAnimationEnabled: Bool {
        didSet {
            persist(isDropMotionAnimationEnabled, for: GeneralSettingsStorage.Keys.dropMotionAnimationEnabled)
        }
    }

    @Published var isTrayLiveActivityEnabled: Bool {
        didSet {
            persist(isTrayLiveActivityEnabled, for: GeneralSettingsStorage.Keys.trayLiveActivityEnabled)
        }
    }

    @Published var dragAndDropActivityMode: DragAndDropActivityMode {
        didSet {
            persist(dragAndDropActivityMode.rawValue, for: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        }
    }

    @Published var isTimerLiveActivityEnabled: Bool {
        didSet {
            persist(isTimerLiveActivityEnabled, for: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        }
    }

    @Published var isTimerDefaultStrokeEnabled: Bool {
        didSet {
            persist(isTimerDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled)
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
        self.isNowPlayingPauseHideTimerEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled
        )
        self.nowPlayingPauseHideDelay = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
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
        self.isDragAndDropLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        self.isDragAndDropDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        self.isDropMotionAnimationEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.dropMotionAnimationEnabled
        )
        self.isTrayLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.trayLiveActivityEnabled
        )
        self.dragAndDropActivityMode = DragAndDropActivityMode.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        )
        self.isTimerLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        self.isTimerDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled)
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
        isNowPlayingPauseHideTimerEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled
        )
        nowPlayingPauseHideDelay = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
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

    func resetDragAndDrop() {
        isDragAndDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        isDragAndDropDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        isDropMotionAnimationEnabled = defaultBool(for: GeneralSettingsStorage.Keys.dropMotionAnimationEnabled)
        isTrayLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.trayLiveActivityEnabled)
        dragAndDropActivityMode = DragAndDropActivityMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        )
    }

    func resetTimer() {
        isTimerLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        isTimerDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled)
    }

    private static func resolvedBool(defaults: UserDefaults, key: String) -> Bool {
        if let currentValue = defaults.object(forKey: key) as? Bool {
            return currentValue
        }

        return (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
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
