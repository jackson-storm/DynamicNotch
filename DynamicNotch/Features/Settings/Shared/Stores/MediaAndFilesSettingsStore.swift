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

    @Published var isNowPlayingArtwork3DEffectEnabled: Bool {
        didSet {
            persist(isNowPlayingArtwork3DEffectEnabled, for: GeneralSettingsStorage.Keys.nowPlayingArtwork3DEffectEnabled)
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

    @Published var nowPlayingSourceFilter: NowPlayingSourceFilter {
        didSet {
            persist(nowPlayingSourceFilter.rawValue, for: GeneralSettingsStorage.Keys.nowPlayingSourceFilter)
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

    @Published var isFileConverterLiveActivityEnabled: Bool {
        didSet {
            persist(
                isFileConverterLiveActivityEnabled,
                for: GeneralSettingsStorage.Keys.fileConverterLiveActivityEnabled
            )
        }
    }

    @Published var fileConverterConvertedTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(fileConverterConvertedTemporaryActivityDuration)
            if clampedValue != fileConverterConvertedTemporaryActivityDuration {
                fileConverterConvertedTemporaryActivityDuration = clampedValue
                return
            }

            persist(
                fileConverterConvertedTemporaryActivityDuration,
                for: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration
            )
        }
    }

    @Published var fileConverterOutputLocation: FileConverterOutputLocation {
        didSet {
            persist(fileConverterOutputLocation.rawValue, for: GeneralSettingsStorage.Keys.fileConverterOutputLocation)
        }
    }

    @Published var fileConverterExistingFileBehavior: FileConverterExistingFileBehavior {
        didSet {
            persist(
                fileConverterExistingFileBehavior.rawValue,
                for: GeneralSettingsStorage.Keys.fileConverterExistingFileBehavior
            )
        }
    }

    @Published var fileConverterFilenameSuffix: String {
        didSet {
            persist(fileConverterFilenameSuffix, for: GeneralSettingsStorage.Keys.fileConverterFilenameSuffix)
        }
    }

    @Published var fileConverterImageQuality: Double {
        didSet {
            let clampedValue = Self.clampFileConverterImageQuality(fileConverterImageQuality)
            if clampedValue != fileConverterImageQuality {
                fileConverterImageQuality = clampedValue
                return
            }

            persist(fileConverterImageQuality, for: GeneralSettingsStorage.Keys.fileConverterImageQuality)
        }
    }

    @Published var fileConverterVideoQuality: FileConverterVideoQuality {
        didSet {
            persist(fileConverterVideoQuality.rawValue, for: GeneralSettingsStorage.Keys.fileConverterVideoQuality)
        }
    }

    @Published var fileConverterAudioQuality: FileConverterAudioQuality {
        didSet {
            persist(fileConverterAudioQuality.rawValue, for: GeneralSettingsStorage.Keys.fileConverterAudioQuality)
        }
    }
    
    @Published var fileTrayUsageMode: FileTrayUsageMode {
        didSet {
            persist(fileTrayUsageMode.rawValue, for: GeneralSettingsStorage.Keys.fileTrayUsageMode)
        }
    }

    @Published var fileTrayScrollDirection: FileTrayScrollDirection {
        didSet {
            persist(fileTrayScrollDirection.rawValue, for: GeneralSettingsStorage.Keys.fileTrayScrollDirection)
        }
    }

    @Published var isFileTrayRemoveButtonHidden: Bool {
        didSet {
            persist(isFileTrayRemoveButtonHidden, for: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden)
        }
    }

    @Published var dragAndDropActivityMode: DragAndDropActivityMode {
        didSet {
            persist(dragAndDropActivityMode.rawValue, for: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        }
    }

    @Published var dragAndDropTargetColorStyle: DragAndDropTargetColorStyle {
        didSet {
            persist(
                dragAndDropTargetColorStyle.rawValue,
                for: GeneralSettingsStorage.Keys.dragAndDropTargetColorStyle
            )
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
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isNowPlayingLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        self.isNowPlayingFavoriteButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        self.isNowPlayingOutputDeviceButtonVisible = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        self.isNowPlayingArtwork3DEffectEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.nowPlayingArtwork3DEffectEnabled
        )
        self.isNowPlayingArtworkTintEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        self.isNowPlayingArtworkStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
        self.isNowPlayingPauseHideTimerEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled
        )
        self.nowPlayingPauseHideDelay = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
        )
        self.nowPlayingSourceFilter = NowPlayingSourceFilter.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.nowPlayingSourceFilter)
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
        self.isFileConverterLiveActivityEnabled = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.fileConverterLiveActivityEnabled
        )
        self.fileConverterConvertedTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(
                for: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration
            )
        )
        self.fileConverterOutputLocation = FileConverterOutputLocation.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileConverterOutputLocation)
        )
        self.fileConverterExistingFileBehavior = FileConverterExistingFileBehavior.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileConverterExistingFileBehavior)
        )
        self.fileConverterFilenameSuffix = defaults.string(
            forKey: GeneralSettingsStorage.Keys.fileConverterFilenameSuffix
        ) ?? (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.fileConverterFilenameSuffix] as? String ?? "-converted")
        self.fileConverterImageQuality = Self.clampFileConverterImageQuality(
            defaults.object(forKey: GeneralSettingsStorage.Keys.fileConverterImageQuality) as? Double ??
            Self.defaultFileConverterImageQuality()
        )
        self.fileConverterVideoQuality = FileConverterVideoQuality.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileConverterVideoQuality)
        )
        self.fileConverterAudioQuality = FileConverterAudioQuality.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileConverterAudioQuality)
        )
        self.fileTrayUsageMode = FileTrayUsageMode.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileTrayUsageMode)
        )
        self.fileTrayScrollDirection = FileTrayScrollDirection.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.fileTrayScrollDirection)
        )
        self.isFileTrayRemoveButtonHidden = Self.resolvedBool(
            defaults: defaults,
            key: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden
        )
        self.dragAndDropActivityMode = DragAndDropActivityMode.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        )
        self.dragAndDropTargetColorStyle = DragAndDropTargetColorStyle.resolved(
            defaults.string(forKey: GeneralSettingsStorage.Keys.dragAndDropTargetColorStyle)
        )
        self.isTimerLiveActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        self.isTimerDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func resetNowPlaying() {
        isNowPlayingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        isNowPlayingFavoriteButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        isNowPlayingOutputDeviceButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        isNowPlayingArtwork3DEffectEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.nowPlayingArtwork3DEffectEnabled
        )
        isNowPlayingArtworkTintEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
        isNowPlayingArtworkStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtworkStrokeEnabled)
        isNowPlayingPauseHideTimerEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled
        )
        nowPlayingPauseHideDelay = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
        )
        nowPlayingSourceFilter = NowPlayingSourceFilter.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.nowPlayingSourceFilter)
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
        isFileConverterLiveActivityEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.fileConverterLiveActivityEnabled
        )
        fileConverterConvertedTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration)
        )
        fileConverterOutputLocation = FileConverterOutputLocation.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileConverterOutputLocation)
        )
        fileConverterExistingFileBehavior = FileConverterExistingFileBehavior.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileConverterExistingFileBehavior)
        )
        fileConverterFilenameSuffix = defaultString(for: GeneralSettingsStorage.Keys.fileConverterFilenameSuffix)
        fileConverterImageQuality = Self.clampFileConverterImageQuality(
            defaultDouble(for: GeneralSettingsStorage.Keys.fileConverterImageQuality)
        )
        fileConverterVideoQuality = FileConverterVideoQuality.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileConverterVideoQuality)
        )
        fileConverterAudioQuality = FileConverterAudioQuality.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileConverterAudioQuality)
        )
        dragAndDropActivityMode = DragAndDropActivityMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.dragAndDropActivityMode)
        )
        dragAndDropTargetColorStyle = DragAndDropTargetColorStyle.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.dragAndDropTargetColorStyle)
        )
        fileTrayUsageMode = FileTrayUsageMode.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileTrayUsageMode)
        )
        fileTrayScrollDirection = FileTrayScrollDirection.resolved(
            defaultString(for: GeneralSettingsStorage.Keys.fileTrayScrollDirection)
        )
        isFileTrayRemoveButtonHidden = defaultBool(for: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden)
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

    static func clampFileConverterImageQuality(_ value: Double) -> Double {
        min(max(value, 0.1), 1.0)
    }

    private static func defaultFileConverterImageQuality() -> Double {
        clampFileConverterImageQuality(
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.fileConverterImageQuality] as? Double) ?? 0.92
        )
    }
}

struct NowPlayingAppearanceOptions {
    let showsFavoriteButton: Bool
    let showsOutputDeviceButton: Bool
    let usesArtwork3DEffect: Bool
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
            usesArtwork3DEffect: isNowPlayingArtwork3DEffectEnabled,
            usesArtworkTint: isNowPlayingArtworkTintEnabled,
            usesArtworkStrokeTint: isNowPlayingArtworkStrokeEnabled && !isDefaultActivityStrokeEnabled
        )
    }
}
