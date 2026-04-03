import Foundation
import SwiftUI

enum NotchDisplayLocation: String, CaseIterable {
    case main
    case builtIn

    var title: LocalizedStringKey {
        switch self {
        case .main:
            return "settings.general.display.main"
        case .builtIn:
            return "settings.general.display.builtin"
        }
    }

    var symbolName: String {
        switch self {
        case .main:
            return "macbook.gen2"
        case .builtIn:
            return "desktopcomputer.and.macbook"
        }
    }
}
