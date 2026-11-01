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
        switch self {
        case .airDrop:
            return .blue

        case .tray:
            return .white
        }
    }

    var activityStrokeColor: Color {
        color.opacity(0.3)
    }

    var acceptsDrop: Bool {
        switch self {
        case .airDrop, .tray:
            return true
        }
    }

    @ViewBuilder
    func titleIcon() -> some View {
        switch self {
        case .airDrop:
            Text("AirDrop")
                .font(.system(size: 12))
                .foregroundStyle(.white)

        case .tray:
            Text("Tray")
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
        }
    }
}
