import SwiftUI

enum DragAndDropActivityMode: String, CaseIterable {
    case airDrop
    case tray
    case combined

    var title: LocalizedStringKey {
        switch self {
        case .airDrop:
            return "AirDrop"
        case .tray:
            return "Tray"
        case .combined:
            return "Combined"
        }
    }

    var targets: [DragAndDropTarget] {
        switch self {
        case .airDrop:
            return [.airDrop]
        case .tray:
            return [.tray]
        case .combined:
            return [.airDrop, .tray]
        }
    }

    var showsAirDrop: Bool {
        targets.contains(.airDrop)
    }

    var showsTray: Bool {
        targets.contains(.tray)
    }

    static func resolved(_ rawValue: String?) -> DragAndDropActivityMode {
        switch rawValue {
        case DragAndDropActivityMode.tray.rawValue:
            return .tray
        case DragAndDropActivityMode.combined.rawValue:
            return .combined
        default:
            return .combined
        }
    }
}
