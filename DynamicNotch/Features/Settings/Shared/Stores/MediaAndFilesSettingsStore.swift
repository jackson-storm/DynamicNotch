import Foundation
import Combine

extension NowPlayingSourceFilter: StoredSettingValue {}
extension DownloadProgressIndicatorStyle: StoredSettingValue {}
extension FileTrayUsageMode: StoredSettingValue {}
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

    @StoredDefault(key: GeneralSettingsStorage.Keys.downloadsProgressIndicatorStyle, defaultValue: .percent)
    var downloadsProgressIndicatorStyle: DownloadProgressIndicatorStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.dragAndDropLiveActivityEnabled, defaultValue: true)
    var isDragAndDropLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled, defaultValue: true)
    var isAirDropLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.trayLiveActivityEnabled, defaultValue: true)
    var isTrayLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileTrayUsageMode, defaultValue: .copy)
    var fileTrayUsageMode: FileTrayUsageMode

    @StoredDefault(key: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden, defaultValue: false)
    var isFileTrayRemoveButtonHidden: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.dragAndDropActivityMode, defaultValue: .airDrop)
    var dragAndDropActivityMode: DragAndDropActivityMode

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerLiveActivityEnabled, defaultValue: true)
    var isTimerLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerSoundEnabled, defaultValue: true)
    var isTimerSoundEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.timerSound, defaultValue: .apex)
    var timerSound: TimerSound

    @StoredDefault(key: GeneralSettingsStorage.Keys.localTimerShortcutKeyCode, defaultValue: 17)
    var localTimerShortcutKeyCode: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.localTimerShortcutModifiers, defaultValue: 786432)
    var localTimerShortcutModifiers: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.localTimerShortcutKeyDisplay, defaultValue: "T")
    var localTimerShortcutKeyDisplay: String

    override init(defaults: UserDefaults) {
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
        isNowPlayingPauseHideTimerEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled)
        nowPlayingPauseHideDelay = defaultInt(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
        nowPlayingSourceFilter = .any
    }

    func resetDownloads() {
        isDownloadsLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.downloadsLiveActivityEnabled)
        downloadsProgressIndicatorStyle = .percent
    }

    func resetDragAndDrop() {
        isDragAndDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.dragAndDropLiveActivityEnabled)
        isAirDropLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.airDropLiveActivityEnabled)
        dragAndDropActivityMode = .airDrop
        resetFileTray()
    }

    func resetFileTray() {
        isTrayLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.trayLiveActivityEnabled)
        fileTrayUsageMode = .copy
        isFileTrayRemoveButtonHidden = defaultBool(for: GeneralSettingsStorage.Keys.fileTrayRemoveButtonHidden)
    }

    func resetTimer() {
        isTimerLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerLiveActivityEnabled)
        isTimerSoundEnabled = defaultBool(for: GeneralSettingsStorage.Keys.timerSoundEnabled)
        timerSound = .apex
        localTimerShortcutKeyCode = 17
        localTimerShortcutModifiers = 786432
        localTimerShortcutKeyDisplay = "T"
    }
}

struct NowPlayingAppearanceOptions {
    let showsFavoriteButton: Bool
    let showsOutputDeviceButton: Bool
    let usesArtwork3DEffect: Bool
}

extension MediaAndFilesSettingsStore {
    var nowPlayingAppearanceOptions: NowPlayingAppearanceOptions {
        .init(
            showsFavoriteButton: isNowPlayingFavoriteButtonVisible,
            showsOutputDeviceButton: isNowPlayingOutputDeviceButtonVisible,
            usesArtwork3DEffect: isNowPlayingArtwork3DEffectEnabled
        )
    }
}
