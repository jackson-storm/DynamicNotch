import SwiftUI

enum SettingsSubPage: Hashable, Identifiable {
    case appearance
    case notch
    case language
    case system
    case permissions
    case softwareUpdate
    case support
    case about
    #if DEBUG
    case debug
    #endif
    case activityPriorities
    case notchDisplay
    case notchAnimation
    case gestures
    case fileTray
    case fileConverter
    case homePagePages
    
    var id: Self { self }
    var titleKey: String {
        switch self {
        case .appearance: return "settings.general.appearance.title"
        case .notch: return "settings.section.notch.title"
        case .language: return "settings.section.language.title"
        case .system: return "settings.general.system.title"
        case .permissions: return "settings.section.permissions.title"
        case .softwareUpdate: return "Software Update"
        case .support: return "settings.general.support.title"
        case .about: return "settings.section.about.title"
        #if DEBUG
        case .debug: return "settings.section.debug.title"
        #endif
        case .activityPriorities: return "settings.notch.priorities.title"
        case .notchDisplay: return "settings.notch.display.title"
        case .notchAnimation: return "Animation"
        case .gestures: return "Gestures"
        case .fileTray: return "Tray"
        case .fileConverter: return "settings.homePage.fileConverter.title"
        case .homePagePages: return "settings.homePage.pages.title"
        }
    }
    
    var fallbackTitle: String {
        switch self {
        case .appearance: return "Appearance"
        case .notch: return "Notch"
        case .language: return "Language"
        case .system: return "System"
        case .permissions: return "Permissions"
        case .softwareUpdate: return "Software Update"
        case .support: return "Support"
        case .about: return "About"
        #if DEBUG
        case .debug: return "Debug"
        #endif
        case .activityPriorities: return "Activity priorities"
        case .notchDisplay: return "Display"
        case .notchAnimation: return "Animation"
        case .gestures: return "Gestures"
        case .fileTray: return "Tray"
        case .fileConverter: return "File Converter"
        case .homePagePages: return "Pages"
        }
    }
    
    var subtitleKey: String {
        switch self {
        case .appearance: return "settings.general.appearance.subtitle"
        case .notch: return "settings.section.notch.subtitle"
        case .language: return "settings.section.language.subtitle"
        case .system: return "settings.general.system.subtitle"
        case .permissions: return "settings.section.permissions.subtitle"
        case .softwareUpdate: return "Check for updates and manage update preferences."
        case .support: return "settings.general.support.subtitle"
        case .about: return "settings.section.about.subtitle"
        #if DEBUG
        case .debug: return "settings.section.debug.subtitle"
        #endif
        case .activityPriorities: return "settings.notch.priorities.subtitle"
        case .notchDisplay: return "settings.notch.display.subtitle"
        case .notchAnimation: return "settings.notch.animation.subtitle"
        case .gestures: return "settings.notch.gestures.subtitle"
        case .fileTray: return "settings.dragAndDrop.tray.subtitle"
        case .fileConverter: return "settings.homePage.fileConverter.subtitle"
        case .homePagePages: return "settings.homePage.pages.subtitle"
        }
    }
    
    var fallbackSubtitle: String {
        switch self {
        case .appearance: return "Choose the interface appearance used by the app."
        case .notch: return "Appearance, animation, and resize feedback."
        case .language: return "Choose the application interface language."
        case .system: return "Manage launch options, Dock, and menu bar icon visibility."
        case .permissions: return "Manage system permissions and access settings."
        case .softwareUpdate: return "Check for updates and manage update preferences."
        case .support: return "Support the project development and donations."
        case .about: return "Project details, links, and release information."
        #if DEBUG
        case .debug: return "Manual previews and event triggers for testing."
        #endif
        case .activityPriorities: return "Configure priority level for each activity."
        case .notchDisplay: return "Configure where and how the notch is displayed."
        case .notchAnimation: return "Set motion parameters and animation speed."
        case .gestures: return "Configure click, hover, and scroll gestures."
        case .fileTray: return "Configure file tray behavior, scroll direction, and appearance."
        case .fileConverter: return "Configure output location, existing file behavior, and quality."
        case .homePagePages: return "Reorder or enable/disable home page cards."
        }
    }
    
    var canReset: Bool {
        switch self {
        case .appearance, .notch, .language, .activityPriorities, .notchDisplay, .notchAnimation, .gestures, .fileTray, .fileConverter, .homePagePages:
            return true
        default:
            return false
        }
    }
}
