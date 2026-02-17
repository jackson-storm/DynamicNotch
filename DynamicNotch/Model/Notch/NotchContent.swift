import Foundation

enum NotchContent: Hashable {
    case none
    case music
    case charger
    case lowPower
    case fullPower
    case bluetooth
    case systemHud(HUDType)
}
