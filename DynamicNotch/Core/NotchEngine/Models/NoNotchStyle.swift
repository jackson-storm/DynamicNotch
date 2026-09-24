//
//  NoNotchStyle.swift
//  DynamicNotch
//

import SwiftUI

enum NoNotchStyle: String, CaseIterable, Codable, Sendable {
    case dynamicIsland
    case notch

    var title: LocalizedStringKey {
        switch self {
        case .dynamicIsland:
            return "settings.notch.style.dynamicIsland"
        case .notch:
            return "settings.notch.style.notch"
        }
    }

    var symbolName: String {
        switch self {
        case .dynamicIsland:
            return "capsule.portrait"
        case .notch:
            return "laptopcomputer"
        }
    }
}

extension NoNotchStyle: StoredSettingValue {}
