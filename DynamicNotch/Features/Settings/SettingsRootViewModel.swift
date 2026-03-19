import Combine
import Foundation

@MainActor
final class SettingsRootViewModel: ObservableObject {
    enum Section: String, CaseIterable, Identifiable {
        case general
        case liveActivity
        case temporaryActivity
        #if DEBUG
        case debug
        #endif
        case about

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general:
                return "General"
            case .liveActivity:
                return "Live Activity"
            case .temporaryActivity:
                return "Temporary"
            #if DEBUG
            case .debug:
                return "Debug"
            #endif
            case .about:
                return "About"
            }
        }

        var subtitle: String {
            switch self {
            case .general:
                return "App startup, placement and notch shape"
            case .liveActivity:
                return "Persistent notch events"
            case .temporaryActivity:
                return "Short-lived notch notifications"
            #if DEBUG
            case .debug:
                return "Manual event previews and test triggers"
            #endif
            case .about:
                return "Project, links and feature overview"
            }
        }

        var systemImage: String {
            switch self {
            case .general:
                return "gearshape.fill"
            case .liveActivity:
                return "waveform.path.ecg.rectangle.fill"
            case .temporaryActivity:
                return "timer"
            #if DEBUG
            case .debug:
                return "ladybug.fill"
            #endif
            case .about:
                return "info.circle.fill"
            }
        }

        var accessibilityIdentifier: String {
            "settings.tab.\(rawValue)"
        }
    }

    @Published var selection: Section {
        didSet {
            defaults.set(selection.rawValue, forKey: Self.selectionKey)
        }
    }

    let liveActivityViewModel: LiveActivitySettingsViewModel
    let temporaryActivityViewModel: TemporaryActivitySettingsViewModel
    #if DEBUG
    let debugViewModel: DebugSettingsViewModel
    #endif

    private let defaults: UserDefaults
    private static let selectionKey = "settings.root.selection"

    init(
        settings: GeneralSettingsViewModel,
        notchViewModel: NotchViewModel? = nil,
        notchEventCoordinator: NotchEventCoordinator? = nil,
        bluetoothViewModel: BluetoothViewModel? = nil,
        powerService: PowerService? = nil,
        networkViewModel: NetworkViewModel? = nil,
        nowPlayingViewModel: NowPlayingViewModel? = nil,
        lockScreenManager: LockScreenManager? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        let storedSelection = defaults.string(forKey: Self.selectionKey) ?? ""

        switch storedSelection {
        case "activities":
            self.selection = .liveActivity
        default:
            self.selection = Section(rawValue: storedSelection) ?? .general
        }

        self.liveActivityViewModel = LiveActivitySettingsViewModel(settings: settings)
        self.temporaryActivityViewModel = TemporaryActivitySettingsViewModel(settings: settings)
        #if DEBUG
        let resolvedNotchViewModel = notchViewModel ?? NotchViewModel(settings: settings)
        let resolvedBluetoothViewModel = bluetoothViewModel ?? BluetoothViewModel()
        let resolvedPowerService = powerService ?? PowerService(startMonitoring: false)
        let resolvedNetworkViewModel = networkViewModel ?? NetworkViewModel()
        let resolvedNowPlayingViewModel = nowPlayingViewModel ?? NowPlayingViewModel(service: InactiveNowPlayingService())
        let resolvedLockScreenManager = lockScreenManager ?? LockScreenManager(
            service: InactiveLockScreenMonitoringService(),
            soundPlayer: InactiveLockScreenSoundPlayer()
        )
        let resolvedCoordinator = notchEventCoordinator ?? NotchEventCoordinator(
            notchViewModel: resolvedNotchViewModel,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            networkViewModel: resolvedNetworkViewModel,
            generalSettingsViewModel: settings,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            lockScreenManager: resolvedLockScreenManager
        )

        self.debugViewModel = DebugSettingsViewModel(
            notchViewModel: resolvedNotchViewModel,
            notchEventCoordinator: resolvedCoordinator,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            networkViewModel: resolvedNetworkViewModel,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            lockScreenManager: resolvedLockScreenManager
        )
        #endif
    }

    var sections: [Section] {
        Section.allCases
    }
}
