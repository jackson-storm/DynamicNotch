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

    var showsAirDrop: Bool {
        self == .airDrop || self == .combined
    }

    var showsTray: Bool {
        self == .tray || self == .combined
    }

    static func resolved(_ rawValue: String?) -> DragAndDropActivityMode {
        switch rawValue {
        case DragAndDropActivityMode.tray.rawValue:
            return .tray
        case DragAndDropActivityMode.combined.rawValue:
            return .combined
        default:
            return .airDrop
        }
    }
}
