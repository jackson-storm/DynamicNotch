import Foundation

@MainActor
final class SettingsRootViewModel {
    #if DEBUG
    let debugViewModel: DebugSettingsViewModel
    #endif

    private let settingsViewModel: SettingsViewModel
    private let defaults: UserDefaults
    private static let selectionKey = "settings.root.selection"

    init(
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel? = nil,
        notchEventCoordinator: NotchEventCoordinator? = nil,
        bluetoothViewModel: BluetoothViewModel? = nil,
        powerService: PowerService? = nil,
        networkViewModel: NetworkViewModel? = nil,
        downloadViewModel: DownloadViewModel? = nil,
        nowPlayingViewModel: NowPlayingViewModel? = nil,
        timerViewModel: TimerViewModel? = nil,
        lockScreenManager: LockScreenManager? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.settingsViewModel = settingsViewModel
        self.defaults = defaults

        #if DEBUG
        self.debugViewModel = Self.makeDebugViewModel(
            settingsViewModel: settingsViewModel,
            notchViewModel: notchViewModel,
            notchEventCoordinator: notchEventCoordinator,
            bluetoothViewModel: bluetoothViewModel,
            powerService: powerService,
            networkViewModel: networkViewModel,
            downloadViewModel: downloadViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            lockScreenManager: lockScreenManager
        )
        #endif
    }

    var sections: [Section] {
        Section.allCases
    }

    func initialSelection() -> Section {
        Section.initialSelection(storedValue: defaults.string(forKey: Self.selectionKey))
    }

    func persistSelection(_ selection: Section) {
        defaults.set(selection.rawValue, forKey: Self.selectionKey)
    }

    func canReset(_ section: Section) -> Bool {
        section.resetGroup != nil
    }

    func reset(_ section: Section) {
        guard let group = section.resetGroup else { return }
        settingsViewModel.reset(group)
    }

    func resetHelpText(for section: Section?, locale: Locale) -> String {
        guard let section else {
            return locale.dn(
                "settings.reset.help.none",
                fallback: "No settings tab selected"
            )
        }

        guard canReset(section) else {
            return locale.dnFormat(
                "settings.reset.help.unavailable",
                fallback: "%@ has no resettable settings",
                section.localizedTitle(locale: locale)
            )
        }

        return locale.dnFormat(
            "settings.reset.help.available",
            fallback: "Reset %@ settings to defaults",
            section.localizedTitle(locale: locale)
        )
    }
}
