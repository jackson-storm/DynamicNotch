import SwiftUI

struct HudCompactContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    let image: String
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            Spacer()
            indicatorView
        }
        .padding(.vertical, 10)
        .padding(.leading, leadingPadding.scaled(by: scale))
        .padding(.trailing, trailingPadding.scaled(by: scale))
    }
    
    private var iconView: some View {
        Image(systemName: image)
            .font(.system(size: isDynamicIsland ? 16 : 18))
            .foregroundColor(.white)
    }
    
    private var indicatorView: some View {
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
    
    private var trailingPadding: CGFloat {
        let basePadding = indicatorStyle == .circle
            ? (isDynamicIsland ? 4 : 14)
            : (isDynamicIsland ? 8 : 16)
        return CGFloat(basePadding)
    }
    
    private var leadingPadding: CGFloat {
        let basePadding = indicatorStyle == .circle
            ? (isDynamicIsland ? 4 : 14)
            : (isDynamicIsland ? 4 : 14)
        return CGFloat(basePadding)
    }
    
    private var barIndicatorWidth: CGFloat {
        50
    }
    
    private var barIndicatorHeight: CGFloat {
        6
    }
    
    private var circleIndicatorSize: CGFloat {
        isDynamicIsland ? 16 : 19
    }
    
    private var circleIndicatorLineWidth: CGFloat {
        3
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
