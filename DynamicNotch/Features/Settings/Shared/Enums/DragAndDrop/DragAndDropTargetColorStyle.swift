import SwiftUI

enum DragAndDropTargetColorStyle: String, CaseIterable {
    case white
    case original
    case accent

    var title: LocalizedStringKey {
        switch self {
        case .white:
            return "White"
        case .original:
            return "Original"
        case .accent:
            return "Accent"
        }
    }

    static func resolved(_ rawValue: String?) -> DragAndDropTargetColorStyle {
        switch rawValue {
        case DragAndDropTargetColorStyle.white.rawValue:
            return .white
        case DragAndDropTargetColorStyle.accent.rawValue:
            return .accent
        default:
            return .original
        }
    }
}
