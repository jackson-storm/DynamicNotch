import Foundation

enum NotchContent: Equatable {
    case none
    case music
    case charger
    case lowPower
    case fullPower
    case audioHardware
    case systemHud(HUDType)
}
