import Foundation
import Combine

extension NowPlayingProgressTintStyle: StoredSettingValue {}
extension NowPlayingSourceFilter: StoredSettingValue {}
extension FloatingLyricsAlignment: StoredSettingValue {}
extension LyricsTranslationLanguage: StoredSettingValue {}
extension FloatingLyricsColorStyle: StoredSettingValue {}
extension FloatingLyricsFontDesign: StoredSettingValue {}
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

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingNotchLyricsEnabled, defaultValue: true)
    var isNowPlayingNotchLyricsEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.nowPlayingFloatingLyricsEnabled, defaultValue: true)
    var isNowPlayingFloatingLyricsEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsShowsTrackInfo, defaultValue: true)
    var isFloatingLyricsTrackInfoVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsShowsNextLine, defaultValue: true)
    var isFloatingLyricsNextLineVisible: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsFontSize, defaultValue: 17)
    var floatingLyricsFontSize: Double

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsWidth, defaultValue: 340)
    var floatingLyricsWidth: Double

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsBackgroundOpacity, defaultValue: 0.82)
    var floatingLyricsBackgroundOpacity: Double

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsAlignment, defaultValue: .leading)
    var floatingLyricsAlignment: FloatingLyricsAlignment

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsColorStyle, defaultValue: .white)
    var floatingLyricsColorStyle: FloatingLyricsColorStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsCustomColor, defaultValue: "#FFD166")
    var floatingLyricsCustomColorHex: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsFontDesign, defaultValue: .standard)
    var floatingLyricsFontDesign: FloatingLyricsFontDesign

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsShadowEnabled, defaultValue: true)
    var isFloatingLyricsShadowEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsHidesOnHover, defaultValue: false)
    var isFloatingLyricsHiddenOnHover: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsHidesWhenPaused, defaultValue: false)
    var isFloatingLyricsHiddenWhenPaused: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsPositionLocked, defaultValue: false)
    var isFloatingLyricsPositionLocked: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsToggleShortcutKeyCode, defaultValue: 3)
    var floatingLyricsToggleShortcutKeyCode: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsToggleShortcutModifiers, defaultValue: 786432)
    var floatingLyricsToggleShortcutModifiers: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.floatingLyricsToggleShortcutKeyDisplay, defaultValue: "F")
    var floatingLyricsToggleShortcutKeyDisplay: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayLaterShortcutKeyCode, defaultValue: 30)
    var lyricsDelayLaterShortcutKeyCode: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayLaterShortcutModifiers, defaultValue: 786432)
    var lyricsDelayLaterShortcutModifiers: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayLaterShortcutKeyDisplay, defaultValue: "]")
    var lyricsDelayLaterShortcutKeyDisplay: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayEarlierShortcutKeyCode, defaultValue: 33)
    var lyricsDelayEarlierShortcutKeyCode: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayEarlierShortcutModifiers, defaultValue: 786432)
    var lyricsDelayEarlierShortcutModifiers: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsDelayEarlierShortcutKeyDisplay, defaultValue: "[")
    var lyricsDelayEarlierShortcutKeyDisplay: String

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsGlobalDelay, defaultValue: 0)
    var lyricsGlobalDelay: Double

    @StoredDefault(key: GeneralSettingsStorage.Keys.notchLyricsTranslationEnabled, defaultValue: true)
    var isNotchLyricsTranslationEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.lyricsTranslationEnabled, defaultValue: false)
    var isLyricsTranslationEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.lyricsTranslationLanguage,
        defaultValue: LyricsTranslationLanguage.systemDefault
    )
    var lyricsTranslationLanguage: LyricsTranslationLanguage

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
        isNowPlayingNotchLyricsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingNotchLyricsEnabled)
        isNowPlayingFloatingLyricsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFloatingLyricsEnabled)
        nowPlayingProgressTintStyle = .default
        isNowPlayingPauseHideTimerEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideTimerEnabled)
        nowPlayingPauseHideDelay = defaultInt(for: GeneralSettingsStorage.Keys.nowPlayingPauseHideDelay)
        nowPlayingSourceFilter = .any
    }

    func resetFloatingLyrics() {
        isNowPlayingFloatingLyricsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.nowPlayingFloatingLyricsEnabled)
        isFloatingLyricsTrackInfoVisible = true
        isFloatingLyricsNextLineVisible = true
        floatingLyricsFontSize = 17
        floatingLyricsWidth = 340
        floatingLyricsBackgroundOpacity = 0.82
        floatingLyricsAlignment = .leading
        floatingLyricsColorStyle = .white
        floatingLyricsCustomColorHex = "#FFD166"
        floatingLyricsFontDesign = .standard
        isFloatingLyricsShadowEnabled = true
        isFloatingLyricsHiddenOnHover = false
        isFloatingLyricsHiddenWhenPaused = false
        isFloatingLyricsPositionLocked = false
        isLyricsTranslationEnabled = false
        isNotchLyricsTranslationEnabled = true
        lyricsTranslationLanguage = .systemDefault
        lyricsGlobalDelay = 0
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
    let showsLyrics: Bool
    let progressTintStyle: NowPlayingProgressTintStyle
}

extension MediaAndFilesSettingsStore {
    var floatingLyricsAppearance: FloatingLyricsAppearance {
        .init(
            showsTrackInfo: isFloatingLyricsTrackInfoVisible,
            showsNextLine: isFloatingLyricsNextLineVisible,
            fontSize: CGFloat(floatingLyricsFontSize),
            width: CGFloat(floatingLyricsWidth),
            backgroundOpacity: floatingLyricsBackgroundOpacity,
            alignment: floatingLyricsAlignment,
            colorStyle: floatingLyricsColorStyle,
            customColorHex: floatingLyricsCustomColorHex,
            fontDesign: floatingLyricsFontDesign,
            showsShadow: isFloatingLyricsShadowEnabled,
            isTranslationEnabled: isLyricsTranslationEnabled,
            translationLanguage: lyricsTranslationLanguage
        )
    }

    var nowPlayingAppearanceOptions: NowPlayingAppearanceOptions {
        .init(
            showsFavoriteButton: isNowPlayingFavoriteButtonVisible,
            showsOutputDeviceButton: isNowPlayingOutputDeviceButtonVisible,
            usesArtwork3DEffect: isNowPlayingArtwork3DEffectEnabled,
            showsLyrics: isNowPlayingNotchLyricsEnabled,
            progressTintStyle: nowPlayingProgressTintStyle
        )
    }
}
