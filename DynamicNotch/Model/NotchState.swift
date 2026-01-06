import SwiftUI

struct NotchState: Equatable {
    var content: NotchContent = .none

    var size: CGSize {
        switch content {
        case .none: return .init(width: 226, height: 38)
        case .music: return .init(width: 305, height: 38)
        case .charger: return .init(width: 405, height: 38)
        case .lowPower: return .init(width: 360, height: 110)
        case .systemHud: return .init(width: 440, height: 38)
        }
    }

    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        switch content {
        case .lowPower: return (18, 36)
        default: return (9, 13)
        }
    }
}
