import SwiftUI

struct HudContentView: View {
    @Environment(\.notchScale) var scale
    
    let image: String
    let text: String
    let level: Int
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let usesColoredLevelTint: Bool
    
    private var barIndicatorWidth: CGFloat {
        switch style {
        case .standard:
            return 60
        case .compact:
            return 60
        case .minimal:
            return 60
        }
    }
    
    private var barIndicatorHeight: CGFloat { 6 }
    
    private var circleIndicatorSize: CGFloat {
        switch style {
        case .standard:
            return 19
        case .compact:
            return 19
        case .minimal:
            return 19
        }
    }

    private var circleIndicatorLineWidth: CGFloat {
        switch style {
        case .standard, .compact:
            return 3
        case .minimal:
            return 3.5
        }
    }

    private var clampedLevel: Int { max(0, min(100, level)) }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard:
            return 14
        case .compact:
            return 14
        case .minimal:
            return 14
        }
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
        HudLevelIndicatorView(
            level: clampedLevel,
            indicatorStyle: indicatorStyle,
            usesColoredLevelTint: usesColoredLevelTint,
            barWidth: barIndicatorWidth,
            barHeight: barIndicatorHeight,
            circleSize: circleIndicatorSize,
            circleLineWidth: circleIndicatorLineWidth
        )
    }
}
