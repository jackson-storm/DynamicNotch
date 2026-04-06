import SwiftUI

struct HudContentView: View {
    @Environment(\.notchScale) var scale
    
    let image: String
    let text: String
    let level: Int
    let style: HudStyle
    let usesColoredLevelTint: Bool
    
    private var indicatorWidth: CGFloat {
        switch style {
        case .standard:
            return 60
        case .compact:
            return 60
        case .minimal:
            return 90
        }
    }
    
    private var indicatorHeight: CGFloat { 6 }
    private var clampedLevel: Int { max(0, min(100, level)) }
    private var filledIndicatorWidth: CGFloat { indicatorWidth * CGFloat(clampedLevel) / 100 }
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard:
            return 14
        case .compact:
            return 16
        case .minimal:
            return 14
        }
    }
    
    private var indicatorFill: some ShapeStyle {
        LinearGradient(
            colors: [
                activeLevelTint.opacity(0.82),
                activeLevelTint,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var levelTint: Color {
        HudLevelStyling.fillTint(for: clampedLevel, isEnabled: true)
    }

    private var activeLevelTint: Color {
        usesColoredLevelTint ? levelTint : HudLevelStyling.fillTint(for: clampedLevel, isEnabled: false)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            switch style {
            case .standard:
                HStack(spacing: 10) {
                    icon
                    
                    Text(verbatim: text)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer(minLength: 12)
                
                HStack(spacing: 10) {
                    AnimatedLevelText(level: clampedLevel, fontSize: 14)
                    indicator
                }
                
            case .compact:
                icon
                Spacer()
                indicator
                
            case .minimal:
                icon
                Spacer()
                AnimatedLevelText(level: clampedLevel, fontSize: 14)
                
            }
        }
        .padding(.horizontal, horizontalPadding.scaled(by: scale))
    }
    
    private var icon: some View {
        Image(systemName: image)
            .font(.system(size: 18))
            .foregroundColor(.white)
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
                    .shadow(color: activeLevelTint.opacity(0.35), radius: 5, y: 0)
            }
            .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: clampedLevel)
    }
}
