//
//  SettingsAppearanceMode.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

import SwiftUI

enum SettingsAppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var title: LocalizedStringKey {
        switch self {
        case .system:
            return "settings.general.appearance.system"
        case .light:
            return "settings.general.appearance.light"
        case .dark:
            return "settings.general.appearance.dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    static func resolved(_ rawValue: String?) -> SettingsAppearanceMode {
        guard let rawValue, let mode = SettingsAppearanceMode(rawValue: rawValue) else {
            return .system
        }

        return mode
    }
}
