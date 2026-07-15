import SwiftUI

enum SettingsSubPage: Hashable, Identifiable {
    case appearance
    case display
    case language
    case system
    case permissions
    case softwareUpdate
    case support
    case about
    
    var id: Self { self }
    var titleKey: String {
        switch self {
        case .appearance: return "settings.general.appearance.title"
        case .display: return "settings.general.display.title"
        case .language: return "settings.section.language.title"
        case .system: return "settings.general.system.title"
        case .permissions: return "settings.section.permissions.title"
        case .softwareUpdate: return "Software Update"
        case .support: return "settings.general.support.title"
        case .about: return "settings.section.about.title"
        }
    }
    
    var fallbackTitle: String {
        switch self {
        case .appearance: return "Appearance"
        case .display: return "Display"
        case .language: return "Language"
        case .system: return "System"
        case .permissions: return "Permissions"
        case .softwareUpdate: return "Software Update"
        case .support: return "Support"
        case .about: return "About"
        }
    }
    
    var subtitleKey: String {
        switch self {
        case .appearance: return "settings.general.appearance.subtitle"
        case .display: return "Configure the display where the notch will be shown."
        case .language: return "settings.section.language.subtitle"
        case .system: return "settings.general.system.subtitle"
        case .permissions: return "settings.section.permissions.subtitle"
        case .softwareUpdate: return "Check for updates and manage update preferences."
        case .support: return "settings.general.support.subtitle"
        case .about: return "settings.section.about.subtitle"
        }
    }
    
    var fallbackSubtitle: String {
        switch self {
        case .appearance: return "Choose the interface appearance used by the app."
        case .display: return "Configure the display where the notch will be shown."
        case .language: return "Choose the application interface language."
        case .system: return "Manage launch options, Dock, and menu bar icon visibility."
        case .permissions: return "Manage system permissions and access settings."
        case .softwareUpdate: return "Check for updates and manage update preferences."
        case .support: return "Support the project development and donations."
        case .about: return "Project details, links, and release information."
        }
    }
    
    var canReset: Bool {
        switch self {
        case .appearance, .display, .language:
            return true
        default:
            return false
        }
    }
}
