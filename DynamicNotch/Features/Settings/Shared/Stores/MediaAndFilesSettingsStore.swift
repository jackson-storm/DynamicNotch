import Foundation
import Combine

extension NowPlayingProgressTintStyle: StoredSettingValue {}
extension NowPlayingSourceFilter: StoredSettingValue {}
extension DownloadProgressIndicatorStyle: StoredSettingValue {}
extension FileConverterOutputLocation: StoredSettingValue {}
extension FileConverterExistingFileBehavior: StoredSettingValue {}
extension FileConverterVideoQuality: StoredSettingValue {}
extension FileConverterAudioQuality: StoredSettingValue {}
extension FileTrayUsageMode: StoredSettingValue {}
extension FileTrayScrollDirection: StoredSettingValue {}
extension DragAndDropActivityMode: StoredSettingValue {}
extension TimerSound: StoredSettingValue {}

@MainActor
final class MediaAndFilesSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled, defaultValue: true)
    var isNowPlayingLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible, defaultValue: true)
    var isNowPlayingFavoriteButtonVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible, defaultValue: true)
    var isNowPlayingOutputDeviceButtonVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingArtwork3DEffectEnabled, defaultValue: true)
    var isNowPlayingArtwork3DEffectEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingProgressTintStyle, defaultValue: .default)
    var nowPlayingProgressTintStyle: NowPlayingProgressTintStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled, defaultValue: true)
    var isNowPlayingPauseHideTimerEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay,
        defaultValue: 3,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var nowPlayingPauseHideDelay: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingSourceFilter, defaultValue: .any)
    var nowPlayingSourceFilter: NowPlayingSourceFilter

    @StoredDefault(key: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled, defaultValue: true)
    var isDownloadsLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled, defaultValue: false)
    var isDownloadsDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.downloadsProgressIndicatorStyle, defaultValue: .percent)
    var downloadsProgressIndicatorStyle: DownloadProgressIndicatorStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.dragAndDropLiveActivityEnabled, defaultValue: true)
    var isDragAndDropLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled, defaultValue: true)
    var isAirDropLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled, defaultValue: false)
    var isDragAndDropDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.trayLiveActivityEnabled, defaultValue: true)
    var isTrayLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterLiveActivityEnabled, defaultValue: true)
    var isFileConverterLiveActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration,
        defaultValue: 2,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var fileConverterConvertedTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterOutputLocation, defaultValue: .sameFolder)
    var fileConverterOutputLocation: FileConverterOutputLocation

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterExistingFileBehavior, defaultValue: .createUniqueName)
    var fileConverterExistingFileBehavior: FileConverterExistingFileBehavior

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterFilenameSuffix, defaultValue: "")
    var fileConverterFilenameSuffix: String

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.fileConverterImageQuality,
        defaultValue: 0.92,
        transform: MediaAndFilesSettingsStore.clampFileConverterImageQuality
    )
    var fileConverterImageQuality: Double

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterVideoQuality, defaultValue: .high)
    var fileConverterVideoQuality: FileConverterVideoQuality

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileConverterAudioQuality, defaultValue: .high)
    var fileConverterAudioQuality: FileConverterAudioQuality

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileTrayUsageMode, defaultValue: .copy)
    var fileTrayUsageMode: FileTrayUsageMode

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileTrayScrollDirection, defaultValue: .horizontal)
    var fileTrayScrollDirection: FileTrayScrollDirection

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden, defaultValue: false)
    var isFileTrayRemoveButtonHidden: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.dragAndDropActivityMode, defaultValue: .airDrop)
    var dragAndDropActivityMode: DragAndDropActivityMode

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerLiveActivityEnabled, defaultValue: true)
    var isTimerLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled, defaultValue: false)
    var isTimerDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerSoundEnabled, defaultValue: true)
    var isTimerSoundEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerSound, defaultValue: .apex)
    var timerSound: TimerSound

    override init(defaults: UserDefaults) {
        if defaults.string(forKey: GeneralSettingsStorage.Keys.nowPlayingProgressTintStyle) == nil {
            let legacyTint = defaults.bool(forKey: GeneralSettingsStorage.Keys.nowPlayingArtworkTintEnabled)
            defaults.set(
                legacyTint ? NowPlayingProgressTintStyle.artwork.rawValue : NowPlayingProgressTintStyle.default.rawValue,
                forKey: GeneralSettingsStorage.Keys.nowPlayingProgressTintStyle
            )
        }

        if defaults.object(forKey: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled) == nil,
           let legacyDownloads = defaults.object(forKey: GeneralSettingsStorage.Keys.legacyFileTransfersLiveActivityEnabled) as? Bool {
            defaults.set(legacyDownloads, forKey: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        }

        super.init(defaults: defaults)
    }

    func resetNowPlaying() {
        isNowPlayingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingLiveActivityEnabled)
        isNowPlayingFavoriteButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFavoriteButtonVisible)
        isNowPlayingOutputDeviceButtonVisible = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingOutputDeviceButtonVisible)
        isNowPlayingArtwork3DEffectEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingArtwork3DEffectEnabled)
        nowPlayingProgressTintStyle = .default
        isNowPlayingPauseHideTimerEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled)
        nowPlayingPauseHideDelay = defaultInt(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
        nowPlayingSourceFilter = .any
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        isDownloadsDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsDefaultStrokeEnabled)
        downloadsProgressIndicatorStyle = .percent
    }

    func resetDragAndDrop() {
        isDragAndDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.dragAndDropLiveActivityEnabled)
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        isDragAndDropDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropDefaultStrokeEnabled)
        dragAndDropActivityMode = .airDrop
        resetFileTray()
        resetFileConverter()
    }

    func resetFileTray() {
        isTrayLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.trayLiveActivityEnabled)
        fileTrayUsageMode = .copy
        fileTrayScrollDirection = .horizontal
        isFileTrayRemoveButtonHidden = defaultBool(for: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden)
    }

    func resetFileConverter() {
        isFileConverterLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fileConverterLiveActivityEnabled)
        fileConverterConvertedTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.fileConverterConvertedTemporaryActivityDuration)
        fileConverterOutputLocation = .sameFolder
        fileConverterExistingFileBehavior = .createUniqueName
        fileConverterFilenameSuffix = defaultString(for: GeneralSettingsStorage.Keys.fileConverterFilenameSuffix)
        fileConverterImageQuality = 0.92
        fileConverterVideoQuality = .high
        fileConverterAudioQuality = .high
    }

    func resetTimer() {
        isTimerLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        isTimerDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerDefaultStrokeEnabled)
        isTimerSoundEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerSoundEnabled)
        timerSound = .apex
    }

    static func clampFileConverterImageQuality(_ value: Double) -> Double {
        min(max(value, 0.1), 1.0)
    }
}

struct NowPlayingAppearanceOptions {
    let showsFavoriteButton: Bool
    let showsOutputDeviceButton: Bool
    let usesArtwork3DEffect: Bool
    let progressTintStyle: NowPlayingProgressTintStyle
}

extension MediaAndFilesSettingsStore {
    var nowPlayingAppearanceOptions: NowPlayingAppearanceOptions {
        resolvedNowPlayingAppearanceOptions(isDefaultActivityStrokeEnabled: false)
    }

    func resolvedNowPlayingAppearanceOptions(
        isDefaultActivityStrokeEnabled: Bool = false
    ) -> NowPlayingAppearanceOptions {
        .init(
            showsFavoriteButton: isNowPlayingFavoriteButtonVisible,
            showsOutputDeviceButton: isNowPlayingOutputDeviceButtonVisible,
            usesArtwork3DEffect: isNowPlayingArtwork3DEffectEnabled,
            progressTintStyle: nowPlayingProgressTintStyle
        )
    }
}
