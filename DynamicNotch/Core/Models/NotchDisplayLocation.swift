import Foundation

enum NotchDisplayLocation: String, CaseIterable {
    case main
    case builtIn

    var title: String {
        switch self {
        case .main:
            return "Show on main display"
        case .builtIn:
            return "Show on built-in display"
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
