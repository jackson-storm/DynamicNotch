//
//  SettingsWindowStyle.swift
//  DynamicNotch
//

import SwiftUI

enum SettingsWindowStyle: String, CaseIterable {
    case regular
    case semiTranslucent

    var title: LocalizedStringKey {
        switch self {
        case .regular:
            return "settings.general.windowStyle.regular"
        case .semiTranslucent:
            return "settings.general.windowStyle.semiTranslucent"
        }
    }

    var symbolName: String {
        switch self {
        case .regular:
            return "macwindow"
        case .semiTranslucent:
            return "macwindow.on.rectangle"
        }
    }

    static func resolved(_ rawValue: String?) -> SettingsWindowStyle {
        guard let rawValue, let style = SettingsWindowStyle(rawValue: rawValue) else {
            return .regular
        }

        return style
    }
}
