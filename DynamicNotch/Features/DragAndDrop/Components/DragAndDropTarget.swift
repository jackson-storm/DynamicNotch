import SwiftUI

enum DragAndDropTarget: String, Hashable, CaseIterable {
    case airDrop
    case tray
    case fileConverter

    var title: LocalizedStringKey {
        switch self {
        case .airDrop:
            return "AirDrop"
            
        case .tray:
            return "Tray"
        case .fileConverter:
            return "Convert"
        }
    }

    var color: Color {
        switch self {
        case .airDrop:
            return .blue

        case .tray:
            return .white
        case .fileConverter:
            return .purple
        }
    }

    var activityStrokeColor: Color {
        color.opacity(0.3)
    }

    var acceptsDrop: Bool {
        switch self {
        case .airDrop, .tray, .fileConverter:
            return true
        }
    }

    @ViewBuilder
    func titleIcon() -> some View {
        switch self {
        case .airDrop:
            Text(verbatim: "AirDrop")
                .font(.system(size: 12))
                .foregroundStyle(.white)

        case .tray:
            Text(verbatim: "Tray")
                .font(.system(size: 12))
                .foregroundStyle(color)
        case .fileConverter:
            Text(verbatim: "Convert")
                .font(.system(size: 12))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    func icon() -> some View {
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
        case .fileConverter:
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
        }
    }
}
