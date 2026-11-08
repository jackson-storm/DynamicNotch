//
//  NotchDisplayLocation.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

import Foundation
import SwiftUI

enum NotchDisplayLocation: String, CaseIterable {
    case main
    case builtIn
    case specific

    var title: LocalizedStringKey {
        switch self {
        case .main:
            return "settings.general.display.main"
        case .builtIn:
            return "settings.general.display.builtin"
        case .specific:
            return "settings.general.display.specific"
        }
    }

    var symbolName: String {
        switch self {
        case .main:
            return "desktopcomputer.and.macbook"
        case .builtIn:
            return "macbook.gen2"
        case .specific:
            return "display.2"
        }
    }
}
