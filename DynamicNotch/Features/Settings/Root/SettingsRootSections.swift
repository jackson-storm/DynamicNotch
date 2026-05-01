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
        case app
        case media
        case connectivity
        case system
        case info

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
        case permissions
        case notch
        case nowPlaying
        case downloads
        case drop
        case timer
        case screenRecording
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
            case "activities", "liveActivity":
                return .nowPlaying
            case "airDrop", "dragAndDrop":
                return .drop
            case "temporaryActivity":
                return .battery
            case "hotspot", "wifi", "vpn":
                return .network
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
    static func sidebarGroupDescriptor(
        for group: SettingsRootViewModel.SidebarGroup
    ) -> SettingsSidebarGroupDescriptor {
        switch group {
        case .app:
            return .init(
                titleKey: "settings.group.application",
                fallbackTitle: "Application"
            )
        case .media:
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
        case .info:
            return .init(
                titleKey: "settings.group.info",
                fallbackTitle: "Info"
            )
        }
    }

    static func sectionDescriptor(
        for section: SettingsRootViewModel.Section
    ) -> SettingsSectionDescriptor {
        switch section {
        case .general:
            return .init(
                sidebarGroup: .app,
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
                tint: .blue,
                resetGroup: .general
            )

        case .permissions:
            return .init(
                sidebarGroup: .app,
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
                sidebarGroup: .app,
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
                sidebarGroup: .media,
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

        case .downloads:
            return .init(
                sidebarGroup: .media,
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
                systemImage: "arrow.down.doc.fill",
                imageName: nil,
                tint: .purple,
                resetGroup: .downloads
            )

        case .drop:
            return .init(
                sidebarGroup: .media,
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
                tint: .blue,
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

        case .network:
            return .init(
                sidebarGroup: .connectivity,
                titleKey: "settings.section.network.title",
                fallbackTitle: "Network",
                subtitleKey: "settings.section.network.subtitle",
                fallbackSubtitle: "Wi-Fi, VPN, and Hotspot activity in one place.",
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
                systemImage: "network",
                imageName: nil,
                tint: .blue,
                resetGroup: .network
            )

        case .battery:
            return .init(
                sidebarGroup: .system,
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
                tint: .green.opacity(0.8),
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
                systemImage: "slider.horizontal.below.rectangle",
                imageName: nil,
                tint: .purple,
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
                sidebarGroup: .app,
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
                sidebarGroup: .app,
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
