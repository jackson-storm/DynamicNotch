import Foundation

enum NotchIntent {
    case showActive(NotchContent)
    case showTemporary(NotchContent, duration: TimeInterval)
    case hideTemporary
}
