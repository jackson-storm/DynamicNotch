import SwiftUI

private struct SettingsSidebarGroupDescriptor {
    let titleKey: String?
    let fallbackTitle: String?
}

private struct SettingsSectionDescriptor {
    let sidebarGroup: SettingsRootViewModel.SidebarGroup
    let titleKey: String
    let fallbackTitle: String
    let subtitleKey: String
    let fallbackSubtitle: String
    let systemImage: String
    let imageName: String?
    let tint: Color
    let iconColor: Color?
    let stroke: Bool?
    let resetGroup: SettingsViewModel.ResetGroup?

    init(
        sidebarGroup: SettingsRootViewModel.SidebarGroup,
        titleKey: String,
        fallbackTitle: String,
        subtitleKey: String,
        fallbackSubtitle: String,
        systemImage: String,
        imageName: String?,
        tint: Color,
        iconColor: Color? = nil,
        stroke: Bool? = nil,
        resetGroup: SettingsViewModel.ResetGroup?
    ) {
        self.sidebarGroup = sidebarGroup
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.subtitleKey = subtitleKey
        self.fallbackSubtitle = fallbackSubtitle
        self.systemImage = systemImage
        self.imageName = imageName
        self.tint = tint
        self.iconColor = iconColor
        self.stroke = stroke
        self.resetGroup = resetGroup
    }
}

extension SettingsRootViewModel {
    enum SidebarGroup: String, CaseIterable, Identifiable {
        case application
        case connectivity
        case mediaAndFiles
        case system

        var id: String { rawValue }

        var titleKey: String? {
            descriptor.titleKey
        }

        var fallbackTitle: String? {
            descriptor.fallbackTitle
        }

        private var descriptor: SettingsSidebarGroupDescriptor {
            SettingsSectionCatalog.sidebarGroupDescriptor(for: self)
        }
    }

    enum Section: String, CaseIterable, Identifiable {
        case general
        #if DEBUG
        case debug
        #endif
    
        case network
        static var wifi: Section { .network }
        static var vpn: Section { .network }
        case bluetooth
        case focus
        case battery
        
        case nowPlaying
        case downloads
        case drop
        
        case hud
        case calendar
        case timer
        case faceID
        case screenRecording
        case externalDevices
        case lockScreen

        static var notifications: Section { .externalDevices }

        var id: String { rawValue }

        var sidebarGroup: SidebarGroup {
            descriptor.sidebarGroup
        }

        var titleKey: String {
            descriptor.titleKey
        }

        var fallbackTitle: String {
            descriptor.fallbackTitle
        }

        var subtitleKey: String {
            descriptor.subtitleKey
        }

        var fallbackSubtitle: String {
            descriptor.fallbackSubtitle
        }

        var systemImage: String {
            descriptor.systemImage
        }

        var imageName: String? {
            descriptor.imageName
        }

        var tint: Color {
            descriptor.tint
        }

        var iconColor: Color {
            descriptor.iconColor ?? .white
        }

        var stroke: Bool {
            descriptor.stroke ?? false
        }

        var resetGroup: SettingsViewModel.ResetGroup? {
            descriptor.resetGroup
        }

        var accessibilityIdentifier: String {
            "settings.tab.\(rawValue)"
        }

        func localizedTitle(locale: Locale) -> String {
            locale.dn(titleKey, fallback: fallbackTitle)
        }

        static func initialSelection(storedValue: String?) -> Self {
            switch storedValue ?? "" {
            case "language":
                return .general
            case "permissions":
                return .general
            case "homePage", "homeScreen":
                return .general
            case "activities", "liveActivity":
                return .nowPlaying
            case "airDrop", "dragAndDrop":
                return .drop
            case "temporaryActivity":
                return .battery
            case "hotspot", "wifi", "vpn", "network":
                return .network
            case "calendar", "events":
                return .calendar
            case "timer", "timers":
                return .timer
            case "notifications", "externalDrives", "externalDevices":
                return .externalDevices
            default:
                return Self(rawValue: storedValue ?? "") ?? .general
            }
        }

        private var descriptor: SettingsSectionDescriptor {
            SettingsSectionCatalog.sectionDescriptor(for: self)
        }
    }
}

private enum SettingsSectionCatalog {
    static func sidebarGroupDescriptor(for group: SettingsRootViewModel.SidebarGroup) -> SettingsSidebarGroupDescriptor {
        switch group {
        case .application:
            return .init(
                titleKey: "settings.group.application",
                fallbackTitle: "Application"
            )
        case .mediaAndFiles:
            return .init(
                titleKey: "settings.group.media",
                fallbackTitle: "Media & Files"
            )
        case .connectivity:
            return .init(
                titleKey: "settings.group.connectivity",
                fallbackTitle: "Connectivity"
            )
        case .system:
            return .init(
                titleKey: "settings.group.system",
                fallbackTitle: "System"
            )
        }
    }

    static func sectionDescriptor(for section: SettingsRootViewModel.Section) -> SettingsSectionDescriptor {
        switch section {
        case .general:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.general.title",
                fallbackTitle: "General",
                subtitleKey: "settings.section.general.subtitle",
                fallbackSubtitle: "Startup, display placement, and app language.",
                systemImage: "gear",
                imageName: nil,
                tint: .gray,
                resetGroup: .general
            )


        case .nowPlaying:
            return .init(
                sidebarGroup: .mediaAndFiles,
                titleKey: "settings.section.nowPlaying.title",
                fallbackTitle: "Now Playing",
                subtitleKey: "settings.section.nowPlaying.subtitle",
                fallbackSubtitle: "Media playback controls shown in the notch.",
                systemImage: "play.fill",
                imageName: nil,
                tint: .pink,
                resetGroup: .nowPlaying
            )

        #if DEBUG
        case .debug:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.debug.title",
                fallbackTitle: "Debug",
                subtitleKey: "settings.section.debug.subtitle",
                fallbackSubtitle: "Manual previews and event triggers for testing.",
                systemImage: "ladybug.fill",
                imageName: nil,
                tint: .red,
                resetGroup: nil
            )
        #endif

            
        case .calendar:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.calendar.title",
                fallbackTitle: "Calendar",
                subtitleKey: "settings.section.calendar.subtitle",
                fallbackSubtitle: "Configure upcoming calendar events settings.",
                systemImage: "calendar",
                imageName: nil,
                tint: .blue,
                stroke: true,
                resetGroup: .calendar
            )

        case .timer:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.timer.title",
                fallbackTitle: "Timer",
                subtitleKey: "settings.section.timer.subtitle",
                fallbackSubtitle: "Clock timer live activity and stroke appearance.",
                systemImage: "timer",
                imageName: nil,
                tint: .orange,
                resetGroup: .timer
            )
            
        case .externalDevices:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.notifications.title",
                fallbackTitle: "External Devices",
                subtitleKey: "settings.section.notifications.subtitle",
                fallbackSubtitle: "Notifications and settings for connected external devices.",
                systemImage: "externaldrive.fill",
                imageName: nil,
                tint: .gray,
                resetGroup: .externalDevices
            )

        case .downloads:
            return .init(
                sidebarGroup: .mediaAndFiles,
                titleKey: "settings.section.downloads.title",
                fallbackTitle: "Downloads",
                subtitleKey: "settings.section.downloads.subtitle",
                fallbackSubtitle: "Live download tracking and transfer previews.",
                systemImage: "arrow.down.circle.fill",
                imageName: nil,
                tint: .blue,
                resetGroup: .downloads
            )

        case .drop:
            return .init(
                sidebarGroup: .mediaAndFiles,
                titleKey: "settings.section.drop.title",
                fallbackTitle: "Drag&Drop",
                subtitleKey: "settings.section.drop.subtitle",
                fallbackSubtitle: "AirDrop and Tray targets for files dragged through the notch.",
                systemImage: "tray.and.arrow.down.fill",
                imageName: nil,
                tint: .gray,
                resetGroup: .drop
            )

        case .screenRecording:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.screenRecording.title",
                fallbackTitle: "Screen Capture",
                subtitleKey: "settings.section.screenRecording.subtitle",
                fallbackSubtitle: "Screenshot and screen recording activity behavior.",
                systemImage: "camera.viewfinder",
                imageName: nil,
                tint: .red,
                resetGroup: .screenRecording
            )

        case .focus:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.focus.title",
                fallbackTitle: "Focus",
                subtitleKey: "settings.section.focus.subtitle",
                fallbackSubtitle: "Focus mode state changes and quick status updates.",
                systemImage: "moon.fill",
                imageName: nil,
                tint: .indigo,
                resetGroup: .focus
            )

        case .bluetooth:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.bluetooth.title",
                fallbackTitle: "Bluetooth",
                subtitleKey: "settings.section.bluetooth.subtitle",
                fallbackSubtitle: "Connection feedback for Bluetooth accessories.",
                systemImage: "headphones",
                imageName: "bluetooth.white",
                tint: .blue,
                resetGroup: .bluetooth
            )

        case .network:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.network.title",
                fallbackTitle: "Network",
                subtitleKey: "settings.section.network.subtitle",
                fallbackSubtitle: "Wi-Fi, Personal Hotspot, and VPN connection settings.",
                systemImage: "network",
                imageName: nil,
                tint: .blue,
                resetGroup: .network
            )

        case .battery:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.battery.title",
                fallbackTitle: "Battery",
                subtitleKey: "settings.section.battery.subtitle",
                fallbackSubtitle: "Charging, low battery, and full battery notifications.",
                systemImage: "battery.100",
                imageName: nil,
                tint: .green,
                resetGroup: .battery
            )

        case .hud:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.hud.title",
                fallbackTitle: "HUD",
                subtitleKey: "settings.section.hud.subtitle",
                fallbackSubtitle: "Custom replacements for volume, brightness, and keyboard HUDs.",
                systemImage: "slider.horizontal.below.sun.max",
                imageName: nil,
                tint: .teal.opacity(0.9),
                resetGroup: .hud
            )

        case .lockScreen:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.lockScreen.title",
                fallbackTitle: "Lock Screen",
                subtitleKey: "settings.section.lockScreen.subtitle",
                fallbackSubtitle: "Lock transitions, sound, and lock-screen media behavior.",
                systemImage: "lock.fill",
                imageName: nil,
                tint: .black,
                resetGroup: .lockScreen
            )

        case .faceID:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.faceID.title",
                fallbackTitle: "Face ID",
                subtitleKey: "settings.section.faceID.subtitle",
                fallbackSubtitle: "Facial recognition unlocking and face profile security.",
                systemImage: "faceid",
                imageName: nil,
                tint: .green,
                resetGroup: .faceID
            )
        }
    }
}
