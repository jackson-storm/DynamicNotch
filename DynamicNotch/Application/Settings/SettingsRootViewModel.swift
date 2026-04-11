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
        case info

        var id: String { rawValue }

        var titleKey: String? {
            switch self {
            case .app:
                return "settings.group.application"
            case .media:
                return "settings.group.media"
            case .connectivity:
                return "settings.group.connectivity"
            case .system:
                return "settings.group.system"
            case .info:
                return "settings.group.info"
            }
        }

        var fallbackTitle: String? {
            switch self {
            case .app:
                return "Application"
            case .media:
                return "Media & Files"
            case .connectivity:
                return "Connectivity"
            case .system:
                return "System"
            case .info:
                return "Info"
            }
        }
    }

    enum Section: String, CaseIterable, Identifiable {
        enum PermissionRequirement {
            case accessibility
            case postEventAccess
        }

        case general
        case notch
        case nowPlaying
        case downloads
        case airDrop
        case bluetooth
        case focus
        case network
        case battery
        case hud
        case lockScreen
        #if DEBUG
        case debug
        #endif
        case about

        var id: String { rawValue }

        var permissionRequirement: PermissionRequirement? {
            switch self {
            case .hud:
                return .accessibility
            case .nowPlaying:
                return .postEventAccess
            default:
                return nil
            }
        }

        var sidebarGroup: SidebarGroup {
            switch self {
            case .general, .notch, .about:
                return .app
            #if DEBUG
            case .debug:
                return .app
            #endif
            case .nowPlaying, .downloads, .airDrop:
                return .media
            case .bluetooth, .focus, .network:
                return .connectivity
            case .battery, .hud, .lockScreen:
                return .system
            }
        }

        var titleKey: String {
            switch self {
            case .general:
                return "settings.section.general.title"
            case .notch:
                return "settings.section.notch.title"
            case .nowPlaying:
                return "settings.section.nowPlaying.title"
            case .downloads:
                return "settings.section.downloads.title"
            case .airDrop:
                return "settings.section.airDrop.title"
            case .focus:
                return "settings.section.focus.title"
            case .bluetooth:
                return "settings.section.bluetooth.title"
            case .network:
                return "settings.section.network.title"
            case .battery:
                return "settings.section.battery.title"
            case .hud:
                return "settings.section.hud.title"
            case .lockScreen:
                return "settings.section.lockScreen.title"
            #if DEBUG
            case .debug:
                return "settings.section.debug.title"
            #endif
            case .about:
                return "settings.section.about.title"
            }
        }

        var fallbackTitle: String {
            switch self {
            case .general:
                return "General"
            case .notch:
                return "Notch"
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

        var subtitleKey: String {
            switch self {
            case .general:
                return "settings.section.general.subtitle"
            case .notch:
                return "settings.section.notch.subtitle"
            case .nowPlaying:
                return "settings.section.nowPlaying.subtitle"
            case .downloads:
                return "settings.section.downloads.subtitle"
            case .airDrop:
                return "settings.section.airDrop.subtitle"
            case .focus:
                return "settings.section.focus.subtitle"
            case .bluetooth:
                return "settings.section.bluetooth.subtitle"
            case .network:
                return "settings.section.network.subtitle"
            case .battery:
                return "settings.section.battery.subtitle"
            case .hud:
                return "settings.section.hud.subtitle"
            case .lockScreen:
                return "settings.section.lockScreen.subtitle"
            #if DEBUG
            case .debug:
                return "settings.section.debug.subtitle"
            #endif
            case .about:
                return "settings.section.about.subtitle"
            }
        }

        var fallbackSubtitle: String {
            switch self {
            case .general:
                return "Startup, display placement, and app language."
            case .notch:
                return "Appearance, animation, and resize feedback."
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
            case .notch:
                return "rectangle.topthird.inset.filled"
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

        var imageName: String? {
            switch self {
            case .airDrop:
                return "airdrop.white"
            case .bluetooth:
                return "bluetooth.white"
            default:
                return nil
            }
        }

        var tint: Color {
            switch self {
            case .general:
                return .blue
            case .notch:
                return .black
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
                return .blue
            case .battery:
                return .green
            case .hud:
                return .orange
            case .lockScreen:
                return .black
            #if DEBUG
            case .debug:
                return .red
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
        lockScreenManager: LockScreenManager? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.settingsViewModel = settingsViewModel
        self.defaults = defaults

        #if DEBUG
        let resolvedNotchViewModel = notchViewModel ?? NotchViewModel(settings: settingsViewModel.application)
        let resolvedBluetoothViewModel = bluetoothViewModel ?? BluetoothViewModel()
        let resolvedPowerService = powerService ?? PowerService(startMonitoring: false)
        let resolvedNetworkViewModel = networkViewModel ?? NetworkViewModel(settings: settingsViewModel.connectivity)
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
            settingsViewModel: settingsViewModel,
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
            settingsViewModel: settingsViewModel,
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
        case "language":
            return .general
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
                localized(section.titleKey, fallback: section.fallbackTitle)
            )
        }

        return locale.dnFormat(
            "settings.reset.help.available",
            fallback: "Reset %@ settings to defaults",
            localized(section.titleKey, fallback: section.fallbackTitle)
        )
    }

    private func resetGroup(for section: Section) -> SettingsViewModel.ResetGroup? {
        switch section {
        case .general:
            return .general
        case .notch:
            return .notch
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
    
    private func localized(_ key: String, fallback: String? = nil) -> String {
        L10n.app(key, fallback: fallback)
    }
}
