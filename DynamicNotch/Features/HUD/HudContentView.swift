import SwiftUI

struct HudContentView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let image: String
    let text: String
    let level: Int
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
        
    var body: some View {
        HStack(spacing: 12) {
            switch style {
            case .standard:
                Text(verbatim: text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer(minLength: 12)
        
                indicator
                
            case .compact:
                icon
                Spacer()
                indicator
                
            case .minimal:
                icon
                Spacer()
                AnimatedLevelText(level: clampedLevel, fontSize: isDynamicIsland ? 14 : 16)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, indicatorStyle == .circle ? horizontalCirclePadding.scaled(by: scale) : horizontalBarPadding.scaled(by: scale))
    }
    
    private var icon: some View {
        Image(systemName: image)
            .font(.system(size: isDynamicIsland ? 16 : 18))
            .foregroundColor(.white)
    }
    
    private var barIndicatorHeight: CGFloat {
        6
    }
    
    private var barIndicatorWidth: CGFloat {
        switch style {
        case .standard:
            return 50
        case .compact:
            return 50
        case .minimal:
            return 60
        }
    }
    
    private var circleIndicatorSize: CGFloat {
        switch style {
        case .standard:
            return isDynamicIsland ? 16 : 19
        case .compact:
            return isDynamicIsland ? 16 : 19
        case .minimal:
            return isDynamicIsland ? 16 : 19
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
    
    private var horizontalBarPadding: CGFloat {
        switch style {
        case .standard:
            return isDynamicIsland ? 8 : 16
        case .compact:
            return isDynamicIsland ? 8 : 14
        case .minimal:
            return isDynamicIsland ? 8 : 14
        }
    }
    
    private var horizontalCirclePadding: CGFloat {
        switch style {
        case .standard:
            return isDynamicIsland ? 6 : 16
        case .compact:
            return isDynamicIsland ? 6 : 14
        case .minimal:
            return isDynamicIsland ? 6 : 14
        }
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
    
    @ViewBuilder
    private var indicator: some View {
        HudLevelIndicatorView(
            level: clampedLevel,
            indicatorStyle: indicatorStyle,
            tintStyle: indicatorTintStyle,
            showsGlow: showsIndicatorGlow,
            barWidth: barIndicatorWidth,
            barHeight: barIndicatorHeight,
            circleSize: circleIndicatorSize,
            circleLineWidth: circleIndicatorLineWidth
        )
    }
}
