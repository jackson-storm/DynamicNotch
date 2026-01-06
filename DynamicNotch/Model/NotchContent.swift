import Foundation

enum NotchContent: Equatable {
    case none
    case music
    case charger
    case lowPower
    case systemHud(HUDType)
}
