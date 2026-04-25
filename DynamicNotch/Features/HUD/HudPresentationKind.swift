import SwiftUI

enum HudPresentationKind {
    case brightness
    case keyboard
    case volume

    var sharedContentID: String {
        switch self {
        case .brightness, .volume:
            return NotchContentRegistry.HUD.system.id
        case .keyboard:
            return NotchContentRegistry.HUD.keyboard.id
        }
    }

    var title: String {
        switch self {
        case .brightness:
            return "Brightness"
        case .keyboard:
            return "Keyboard Brightness"
        case .volume:
            return "Volume"
        }
    }

    func symbolName(for level: Int) -> String {
        switch self {
        case .brightness:
            switch level {
            case ..<1:
                return "sun.min.fill"
            case ..<50:
                return "sun.min.fill"
            default:
                return "sun.max.fill"
            }

        case .keyboard:
            switch level {
            case ..<1:
                return "light.min"
            default:
                return "light.max"
            }

        case .volume:
            switch level {
            case ..<1:
                return "speaker.slash.fill"
            case ..<20:
                return "speaker.fill"
            case ..<50:
                return "speaker.wave.1.fill"
            case ..<70:
                return "speaker.wave.2.fill"
            default:
                return "speaker.wave.3.fill"
            }
        }
    }
}
