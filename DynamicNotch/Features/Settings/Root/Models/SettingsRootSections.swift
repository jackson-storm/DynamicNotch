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
    let searchKeywords: [String]
    let systemImage: String
    let imageName: String?
    let tint: Color
    let resetGroup: SettingsViewModel.ResetGroup?
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
        case homePage
        case notch
        case permissions
        case about
        #if DEBUG
        case debug
        #endif
    
        case wifi
        case bluetooth
        case vpn
        case battery
        case focus
        
        case nowPlaying
        case downloads
        case drop
        
        case hud
        case timer
        case calendar
        case screenRecording
        case lockScreen

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

        var searchKeywords: [String] {
            descriptor.searchKeywords
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
                return .permissions
            case "homePage", "homeScreen":
                return .homePage
            case "activities", "liveActivity":
                return .nowPlaying
            case "airDrop", "dragAndDrop":
                return .drop
            case "temporaryActivity":
                return .battery
            case "hotspot", "wifi", "vpn":
                return .wifi
            case "calendar", "events":
                return .calendar
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
                searchKeywords: [
                    "launch at login",
                    "dock icon",
                    "menu bar",
                    "appearance",
                    "language",
                    "display",
                    "full screen",
                    "fullscreen"
                ],
                systemImage: "gear",
                imageName: nil,
                tint: .gray,
                resetGroup: .general
            )

        case .permissions:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.permissions.title",
                fallbackTitle: "Permissions",
                subtitleKey: "settings.section.permissions.subtitle",
                fallbackSubtitle: "Accessibility, Bluetooth, and media control access required by app features.",
                searchKeywords: [
                    "permissions",
                    "accessibility",
                    "bluetooth",
                    "media controls",
                    "grant access",
                    "privacy settings"
                ],
                systemImage: "checkmark.seal.fill",
                imageName: nil,
                tint: .green.opacity(0.8),
                resetGroup: nil
            )

        case .notch:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.notch.title",
                fallbackTitle: "Notch",
                subtitleKey: "settings.section.notch.subtitle",
                fallbackSubtitle: "Appearance, animation, and resize feedback.",
                searchKeywords: [
                    "background",
                    "stroke",
                    "liquid glass",
                    "animation",
                    "speed",
                    "resize",
                    "width",
                    "height"
                ],
                systemImage: "rectangle.topthird.inset.filled",
                imageName: nil,
                tint: .black,
                resetGroup: .notch
            )

        case .nowPlaying:
            return .init(
                sidebarGroup: .mediaAndFiles,
                titleKey: "settings.section.nowPlaying.title",
                fallbackTitle: "Now Playing",
                subtitleKey: "settings.section.nowPlaying.subtitle",
                fallbackSubtitle: "Media playback controls shown in the notch.",
                searchKeywords: [
                    "player appearance",
                    "favorite",
                    "output device",
                    "progress",
                    "artwork",
                    "stroke",
                    "playback"
                ],
                systemImage: "music.note",
                imageName: nil,
                tint: .red,
                resetGroup: .nowPlaying
            )

        case .homePage:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.homePage.title",
                fallbackTitle: "Home Page",
                subtitleKey: "settings.section.homePage.subtitle",
                fallbackSubtitle: "Configure pages visible on the notch home page.",
                searchKeywords: [
                    "home page",
                    "home",
                    "page",
                    "pages",
                    "reorder",
                    "live activity"
                ],
                systemImage: "house.fill",
                imageName: nil,
                tint: .blue,
                resetGroup: .homePage
            )

            
        case .calendar:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.calendar.title",
                fallbackTitle: "Calendar",
                subtitleKey: "settings.section.calendar.subtitle",
                fallbackSubtitle: "Configure upcoming calendar events settings.",
                searchKeywords: [
                    "Calendar",
                    "Events"
                ],
                systemImage: "calendar",
                imageName: nil,
                tint: .blue,
                resetGroup: .calendar
            )

        case .downloads:
            return .init(
                sidebarGroup: .mediaAndFiles,
                titleKey: "settings.section.downloads.title",
                fallbackTitle: "Downloads",
                subtitleKey: "settings.section.downloads.subtitle",
                fallbackSubtitle: "Live download tracking and transfer previews.",
                searchKeywords: [
                    "download",
                    "transfer",
                    "file",
                    "download style",
                    "progress indicator",
                    "default stroke",
                    "live activity"
                ],
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
                searchKeywords: [
                    "drag and drop",
                    "drag",
                    "drop",
                    "airdrop",
                    "tray",
                    "share",
                    "transfer",
                    "stroke"
                ],
                systemImage: "tray.and.arrow.down.fill",
                imageName: nil,
                tint: .black,
                resetGroup: .drop
            )

        case .timer:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.timer.title",
                fallbackTitle: "Timer",
                subtitleKey: "settings.section.timer.subtitle",
                fallbackSubtitle: "Clock timer live activity and stroke appearance.",
                searchKeywords: [
                    "timer",
                    "clock",
                    "countdown",
                    "live activity",
                    "stroke"
                ],
                systemImage: "timer",
                imageName: nil,
                tint: .orange,
                resetGroup: .timer
            )

        case .screenRecording:
            return .init(
                sidebarGroup: .system,
                titleKey: "settings.section.screenRecording.title",
                fallbackTitle: "Screen Recording",
                subtitleKey: "settings.section.screenRecording.subtitle",
                fallbackSubtitle: "Recording indicator behavior and stroke appearance.",
                searchKeywords: [
                    "screen recording",
                    "recording",
                    "capture",
                    "record",
                    "indicator",
                    "stroke",
                    "live activity"
                ],
                systemImage: "record.circle",
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
                searchKeywords: [
                    "focus",
                    "icons only",
                    "style",
                    "stroke",
                    "duration"
                ],
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
                searchKeywords: [
                    "bluetooth",
                    "device",
                    "detailed",
                    "battery indicator",
                    "percent",
                    "circle",
                    "stroke",
                    "duration"
                ],
                systemImage: "headphones",
                imageName: "bluetooth.white",
                tint: .blue,
                resetGroup: .bluetooth
            )

        case .wifi:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.wifi.title",
                fallbackTitle: "Wi-Fi",
                subtitleKey: "settings.section.wifi.subtitle",
                fallbackSubtitle: "Wi-Fi and Personal Hotspot activity.",
                searchKeywords: [
                    "wifi",
                    "vpn",
                    "hotspot",
                    "timer",
                    "details",
                    "change",
                    "stroke",
                    "duration"
                ],
                systemImage: "wifi",
                imageName: nil,
                tint: .blue,
                resetGroup: .wifi
            )

        case .vpn:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.vpn.title",
                fallbackTitle: "VPN",
                subtitleKey: "settings.section.vpn.subtitle",
                fallbackSubtitle: "Select the preferred VPN connection and configure behavior.",
                searchKeywords: [
                    "vpn",
                    "connection",
                    "select",
                    "preferred"
                ],
                systemImage: "network.badge.shield.half.filled",
                imageName: nil,
                tint: .blue,
                resetGroup: .vpn
            )

        case .battery:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.battery.title",
                fallbackTitle: "Battery",
                subtitleKey: "settings.section.battery.subtitle",
                fallbackSubtitle: "Charging, low battery, and full battery notifications.",
                searchKeywords: [
                    "charging",
                    "low battery",
                    "full battery",
                    "threshold",
                    "stroke",
                    "style",
                    "duration"
                ],
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
                searchKeywords: [
                    "brightness",
                    "keyboard",
                    "volume",
                    "level indicator",
                    "bar",
                    "circle",
                    "stroke",
                    "duration"
                ],
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
                searchKeywords: [
                    "lock sound",
                    "unlock sound",
                    "media panel",
                    "widget appearance",
                    "background brightness",
                    "accent tint",
                    "liquid glass"
                ],
                systemImage: "lock.fill",
                imageName: nil,
                tint: .black,
                resetGroup: .lockScreen
            )

        #if DEBUG
        case .debug:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.debug.title",
                fallbackTitle: "Debug",
                subtitleKey: "settings.section.debug.subtitle",
                fallbackSubtitle: "Manual previews and event triggers for testing.",
                searchKeywords: [
                    "preview",
                    "trigger",
                    "debug"
                ],
                systemImage: "ladybug",
                imageName: nil,
                tint: .red,
                resetGroup: nil
            )
        #endif

        case .about:
            return .init(
                sidebarGroup: .application,
                titleKey: "settings.section.about.title",
                fallbackTitle: "About",
                subtitleKey: "settings.section.about.subtitle",
                fallbackSubtitle: "Project details, links, and release information.",
                searchKeywords: [
                    "version",
                    "website",
                    "about"
                ],
                systemImage: "info.circle",
                imageName: nil,
                tint: .secondary,
                resetGroup: nil
            )
        }
    }
}
