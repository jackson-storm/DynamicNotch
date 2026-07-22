import SwiftUI

enum DragAndDropTarget: String, Hashable, CaseIterable {
    case airDrop
    case tray

    var title: LocalizedStringKey {
        switch self {
        case .airDrop:
            return "AirDrop"
            
        case .tray:
            return "Tray"
        }
    }

    var color: Color {
        color(for: .original)
    }

    func color(for style: DragAndDropTargetColorStyle) -> Color {
        switch style {
        case .white:
            return .white

        case .original:
            return originalColor

        case .accent:
            return .accentColor
        }
    }

    func activityStrokeColor(for style: DragAndDropTargetColorStyle) -> Color {
        switch style {
        case .white:
            return .white.opacity(0.2)

        case .original, .accent:
            return color(for: style).opacity(0.3)
        }
    }

    private var originalColor: Color {
        switch self {
        case .airDrop:
            return .blue
            
        case .tray:
            return .white
        }
    }

    private func titleColor(for style: DragAndDropTargetColorStyle) -> Color {
        switch style {
        case .white, .original, .accent:
            return color(for: style)
        }
    }

    var acceptsDrop: Bool {
        switch self {
        case .airDrop, .tray:
            return true
        }
    }
    
    @ViewBuilder
    func titleIcon(colorStyle: DragAndDropTargetColorStyle = .original) -> some View {
        switch self {
        case .airDrop:
            Text(verbatim: "AirDrop")
                .font(.system(size: 12))
                .foregroundStyle(titleColor(for: colorStyle))
            
        case .tray:
            Text(verbatim: "Tray")
                .font(.system(size: 12))
                .foregroundStyle(titleColor(for: colorStyle))
        }
    }

    @ViewBuilder
    func icon(colorStyle: DragAndDropTargetColorStyle = .original) -> some View {
        let color = color(for: colorStyle)

        switch self {
        case .airDrop:
            Image("airdrop.white")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            
        case .tray:
            Image(systemName: "tray.full.fill")
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
        }
    }
}
