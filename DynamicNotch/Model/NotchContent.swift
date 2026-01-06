import Foundation

enum NotchContent: Equatable {
    case none
    case music
    case charger
    case lowPower
    case fullPower
    case systemHud(HUDType)
}
