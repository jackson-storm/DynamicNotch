import SwiftUI

enum DragAndDropTarget: String, Equatable, CaseIterable {
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
            return .accentColor
            
        case .tray:
            return .white.opacity(0.6)
        }
    }
    
    @ViewBuilder
    var titleIcon: some View {
        switch self {
        case .airDrop:
            Text(verbatim: "AirDrop")
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)
            
        case .tray:
            Text(verbatim: "File Tray")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.8))
        }
    }

    @ViewBuilder
    var icon: some View {
        switch self {
        case .airDrop:
            Image("airdrop.white")
                .resizable()
                .renderingMode(.template)
                .frame(width: 28, height: 28)
            
        case .tray:
            Image(systemName: "tray.full.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
        }
    }
}
