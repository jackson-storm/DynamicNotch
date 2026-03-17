import SwiftUI

enum HudPresentationKind {
    case brightness
    case keyboard
    case volume
    
    var sharedContentID: String {
        switch self {
        case .brightness, .volume:
            return "hud.system"
        case .keyboard:
            return "hud.keyboard"
        }
    }
    
    var title: String {
        switch self {
        case .brightness:
            return "Brightness"
        case .keyboard:
            return "Keyboard"
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
            case ..<34:
                return "sun.min.fill"
            case ..<67:
                return "sun.max.fill"
            default:
                return "sun.max.fill"
            }
            
        case .keyboard:
            return "light.max"
            
        case .volume:
            switch level {
            case ..<1:
                return "speaker.slash.fill"
            case ..<34:
                return "speaker.fill"
            case ..<67:
                return "speaker.wave.1.fill"
            default:
                return "speaker.wave.3.fill"
            }
        }
    }
}

struct HudNotchContent: NotchContentProtocol {
    var id: String {kind.sharedContentID}
    let kind: HudPresentationKind
    let level: Int
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            HudContent(
                image: kind.symbolName(for: level),
                text: kind.title,
                level: level
            )
        )
    }
}

private struct HudContent: View {
    @Environment(\.notchScale) var scale
    
    var image: String
    var text: String
    var level: Int
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: image)
                Text(text)
            }
            
            Spacer()
            
            HStack {
                Text("\(level)")
                indicator
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.8))
    }
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
                    .fill(Color.white)
                    .frame(width: filledIndicatorWidth, height: indicatorHeight)
            }
            .animation(.easeInOut(duration: 0.1), value: clampedLevel)
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
    
    private var indicatorWidth: CGFloat { 64 }
    
    private var indicatorHeight: CGFloat { 6 }
    
    private var filledIndicatorWidth: CGFloat {
        indicatorWidth * CGFloat(clampedLevel) / 100
    }
}
