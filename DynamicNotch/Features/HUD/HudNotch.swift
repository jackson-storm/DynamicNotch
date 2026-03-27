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
            HudContent(image: kind.symbolName(for: level), text: kind.title, level: level)
        )
    }
}

private struct HudContent: View {
    @Environment(\.notchScale) var scale
    
    var image: String
    var text: String
    var level: Int
    
    private let levelAnimation = Animation.snappy(duration: 0.28, extraBounce: 0.12)
    
    private var indicatorWidth: CGFloat { 64 }
    private var indicatorHeight: CGFloat { 6 }
    private var clampedLevel: Int { max(0, min(100, level)) }
    private var filledIndicatorWidth: CGFloat { indicatorWidth * CGFloat(clampedLevel) / 100 }
    
    private var indicatorFill: some ShapeStyle {
        LinearGradient(
            colors: [
                levelTint.opacity(0.82),
                levelTint,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    private var levelTint: Color {
        guard clampedLevel > 0 else {
            return .white.opacity(0.45)
        }
        
        let progress = Double(clampedLevel) / 100
        let startHue: Double = 0.33
        let endHue: Double = 0.0
        let hue = startHue + (endHue - startHue) * progress
        return Color(
            hue: hue,
            saturation: 0.86,
            brightness: 0.98
        )
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: image)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                AnimatedHudLevelText(level: clampedLevel)
                indicator
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
    }
    
    @ViewBuilder
    private var indicator: some View {
        RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
                    .fill(indicatorFill)
                    .frame(width: filledIndicatorWidth, height: indicatorHeight)
                    .shadow(color: levelTint.opacity(0.35), radius: 5, y: 0)
            }
            .animation(levelAnimation, value: clampedLevel)
    }
}

private struct AnimatedHudLevelText: View {
    let level: Int
    
    var body: some View {
        Text(level, format: .number)
            .font(.system(size: 14, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.8))
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: level)
    }
}

