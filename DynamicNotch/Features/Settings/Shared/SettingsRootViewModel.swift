import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsRootViewModel {
    enum SidebarGroup: String, CaseIterable, Identifiable {
        case app
        case media
        case connectivity
        case system
        #if DEBUG
        case developer
        #endif
        case info

        var id: String { rawValue }

        var title: String? {
            switch self {
            case .app:
                return "Application"
            case .media:
                return "Media & Files"
            case .connectivity:
                return "Connectivity"
            case .system:
                return "System"
            #if DEBUG
            case .developer:
                return "Developer"
            #endif
            case .info:
                return "Info"
            }
        }
    }

    enum Section: String, CaseIterable, Identifiable {
        case general
        case nowPlaying
        case downloads
        case airDrop
        case focus
        case bluetooth
        case network
        case battery
        case hud
        case lockScreen
        #if DEBUG
        case debug
        #endif
        case about

        var id: String { rawValue }

        var sidebarGroup: SidebarGroup {
            switch self {
            case .general:
                return .app
            case .nowPlaying, .downloads, .airDrop:
                return .media
            case .focus, .bluetooth, .network:
                return .connectivity
            case .battery, .hud, .lockScreen:
                return .system
            #if DEBUG
            case .debug:
                return .developer
            #endif
            case .about:
                return .info
            }
        }

        var title: String {
            switch self {
            case .general:
                return "General"
            case .nowPlaying:
                return "Now Playing"
            case .downloads:
                return "Downloads"
            case .airDrop:
                return "AirDrop"
            case .focus:
                return "Focus"
            case .bluetooth:
                return "Bluetooth"
            case .network:
                return "Network"
            case .battery:
                return "Battery"
            case .hud:
                return "HUD"
            case .lockScreen:
                return "Lock Screen"
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
                return "Startup, placement, appearance, and notch sizing."
            case .nowPlaying:
                return "Media playback controls shown in the notch."
            case .downloads:
                return "Live download tracking and transfer previews."
            case .airDrop:
                return "Drag-and-drop sharing through the notch."
            case .focus:
                return "Focus mode state changes and quick status updates."
            case .bluetooth:
                return "Connection feedback for Bluetooth accessories."
            case .network:
                return "Wi-Fi, VPN, and Hotspot activity in one place."
            case .battery:
                return "Charging, low battery, and full battery notifications."
            case .hud:
                return "Custom replacements for volume, brightness, and keyboard HUDs."
            case .lockScreen:
                return "Lock transitions, sound, and lock-screen media behavior."
            #if DEBUG
            case .debug:
                return "Manual previews and event triggers for testing."
            #endif
            case .about:
                return "Project details, links, and release information."
            }
        }

        var systemImage: String {
            switch self {
            case .general:
                return "gear"
            case .nowPlaying:
                return "music.note"
            case .downloads:
                return "arrow.down.doc.fill"
            case .airDrop:
                return "dot.radiowaves.left.and.right"
            case .focus:
                return "moon.fill"
            case .bluetooth:
                return "headphones"
            case .network:
                return "network"
            case .battery:
                return "battery.100"
            case .hud:
                return "slider.horizontal.below.rectangle"
            case .lockScreen:
                return "lock.fill"
            #if DEBUG
            case .debug:
                return "ladybug"
            #endif
            case .about:
                return "info.circle"
            }
        }

        var tint: Color {
            switch self {
            case .general:
                return .blue
            case .nowPlaying:
                return .red
            case .downloads:
                return .purple
            case .airDrop:
                return .blue
            case .focus:
                return .indigo
            case .bluetooth:
                return .blue
            case .network:
                return .pink
            case .battery:
                return .green
            case .hud:
                return .orange
            case .lockScreen:
                return .black
            #if DEBUG
            case .debug:
                return .green
            #endif
            case .about:
                return .secondary
            }
        }

        var accessibilityIdentifier: String {
            "settings.tab.\(rawValue)"
        }
    }

    #if DEBUG
    let debugViewModel: DebugSettingsViewModel
    #endif

    private let settings: GeneralSettingsViewModel
    private let defaults: UserDefaults
    private static let selectionKey = "settings.root.selection"

    init(
        settings: GeneralSettingsViewModel,
        notchViewModel: NotchViewModel? = nil,
        notchEventCoordinator: NotchEventCoordinator? = nil,
        bluetoothViewModel: BluetoothViewModel? = nil,
        powerService: PowerService? = nil,
        networkViewModel: NetworkViewModel? = nil,
        downloadViewModel: DownloadViewModel? = nil,
        nowPlayingViewModel: NowPlayingViewModel? = nil,
        lockScreenManager: LockScreenManager? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.defaults = defaults

        #if DEBUG
        let resolvedNotchViewModel = notchViewModel ?? NotchViewModel(settings: settings)
        let resolvedBluetoothViewModel = bluetoothViewModel ?? BluetoothViewModel()
        let resolvedPowerService = powerService ?? PowerService(startMonitoring: false)
        let resolvedNetworkViewModel = networkViewModel ?? NetworkViewModel()
        let resolvedDownloadViewModel = downloadViewModel ?? DownloadViewModel(
            monitor: InactiveDownloadMonitor()
        )
        let resolvedAirDropViewModel = AirDropNotchViewModel()
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
            downloadViewModel: resolvedDownloadViewModel,
            airDropViewModel: resolvedAirDropViewModel,
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
            downloadViewModel: resolvedDownloadViewModel,
            generalSettingsViewModel: settings,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            lockScreenManager: resolvedLockScreenManager
        )
        #endif
    }

    var sections: [Section] {
        Section.allCases
    }

    func initialSelection() -> Section {
        let storedSelection = defaults.string(forKey: Self.selectionKey) ?? ""
        switch storedSelection {
        case "activities", "liveActivity":
            return .nowPlaying
        case "temporaryActivity":
            return .battery
        case "hotspot", "wifi", "vpn":
            return .network
        default:
            return Section(rawValue: storedSelection) ?? .general
        }
    }

    func persistSelection(_ selection: Section) {
        defaults.set(selection.rawValue, forKey: Self.selectionKey)
    }

    func canReset(_ section: Section) -> Bool {
        resetGroup(for: section) != nil
    }

    func reset(_ section: Section) {
        guard let group = resetGroup(for: section) else { return }
        settings.reset(group)
    }

    func resetHelpText(for section: Section?) -> String {
        guard let section else {
            return "No settings tab selected"
        }

        guard canReset(section) else {
            return "\(section.title) has no resettable settings"
        }

        return "Reset \(section.title) settings to defaults"
    }

    private func resetGroup(for section: Section) -> GeneralSettingsViewModel.ResetGroup? {
        switch section {
        case .general:
            return .general
        case .nowPlaying:
            return .nowPlaying
        case .downloads:
            return .downloads
        case .airDrop:
            return .airDrop
        case .focus:
            return .focus
        case .bluetooth:
            return .bluetooth
        case .network:
            return .network
        case .battery:
            return .battery
        case .hud:
            return .hud
        case .lockScreen:
            return .lockScreen
        #if DEBUG
        case .debug:
            return nil
        #endif
        case .about:
            return nil
        }
    }
}
