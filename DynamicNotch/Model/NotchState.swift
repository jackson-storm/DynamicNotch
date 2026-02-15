import SwiftUI

struct NotchState: Equatable {
    var activeContent: NotchContent = .none
    var temporaryContent: NotchContent? = nil
    var content: NotchContent { temporaryContent ?? activeContent }

    var size: CGSize {
        switch content {
        case .none: return .init(width: 226, height: 38)
        case .music: return .init(width: 305, height: 38)
        case .charger: return .init(width: 405, height: 38)
        case .lowPower: return .init(width: 360, height: 110)
        case .fullPower: return .init(width: 300, height: 100)
        case .audioHardware: return .init(width: 405, height: 38)
        case .systemHud: return .init(width: 440, height: 38)
        }
    }

    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        switch content {
        case .lowPower: return (18, 36)
        case .fullPower: return (18, 36)
        default: return (9, 13)
        }
    }
    
    var offsetXTransition: CGFloat {
        switch content {
        case .none: return 0
        case .music: return -60
        case .charger: return -60
        case .lowPower: return -60
        case .fullPower: return -40
        case .audioHardware: return -60
        case .systemHud: return -60
        }
    }
    
    var offsetYTransition: CGFloat {
        switch content {
        case .none: return 0
        case .music: return 0
        case .charger: return 0
        case .lowPower: return -60
        case .fullPower: return -40
        case .audioHardware: return 0
        case .systemHud: return 0
        }
    }
}
