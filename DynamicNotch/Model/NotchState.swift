import SwiftUI

struct NotchState: Equatable {
    var content: NotchContent = .none

    var size: CGSize {
        switch content {
        case .none: return .init(width: 226, height: 38)
        case .music: return .init(width: 300, height: 38)
        case .notification: return .init(width: 350, height: 200)
        case .charger: return .init(width: 405, height: 38)
        case .lowPower: return .init(width: 360, height: 110)
        }
    }

    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        switch content {
        case .notification: return (18, 26)
        case .lowPower: return (18, 36)
        default: return (9, 13)
        }
    }
}
