import SwiftUI

enum DragAndDropActivityMode: String, CaseIterable {
    case airDrop
    case tray
    case fileConverter
    case combined

    var title: LocalizedStringKey {
        switch self {
        case .airDrop:
            return "AirDrop"
        case .tray:
            return "Tray"
        case .fileConverter:
            return "File Converter"
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
        case .fileConverter:
            return [.fileConverter]
        case .combined:
            return [.airDrop, .tray, .fileConverter]
        }
    }

    var showsAirDrop: Bool {
        targets.contains(.airDrop)
    }

    var showsTray: Bool {
        targets.contains(.tray)
    }

    var showsFileConverter: Bool {
        targets.contains(.fileConverter)
    }

    static func resolved(_ rawValue: String?) -> DragAndDropActivityMode {
        switch rawValue {
        case DragAndDropActivityMode.tray.rawValue:
            return .tray
        case DragAndDropActivityMode.fileConverter.rawValue:
            return .fileConverter
        case DragAndDropActivityMode.combined.rawValue:
            return .combined
        default:
            return .combined
        }
    }
}
