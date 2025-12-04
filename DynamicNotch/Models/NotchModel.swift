import SwiftUI

struct NotchSize {
    var width: CGFloat
    var height: CGFloat
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat
}

enum NotchState {
    case compact
    case expanded
}

enum NotchContentKind {
    case defaultNotch
    case player
    case charger
}
