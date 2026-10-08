import SwiftUI

struct HudCompactContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    let image: String
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        HStack {
            Image(systemName: image)
                .font(.system(size: isNotchlessScreen ? 16 : 18))
                .foregroundColor(.white)
            
            Spacer()
            
            HudLevelIndicatorView(
                level: clampedLevel,
                indicatorStyle: indicatorStyle,
                tintStyle: indicatorTintStyle,
                showsGlow: showsIndicatorGlow,
                barWidth: 50,
                barHeight: 6,
                circleSize: isNotchlessScreen ? 16 : 19,
                circleLineWidth: 3
            )
        }
        .padding(.leading, leadingPadding.scaled(by: scale))
        .padding(.trailing, trailingPadding.scaled(by: scale))
    }
    
    private var trailingPadding: CGFloat {
        let basePadding = indicatorStyle == .circle
            ? (isNotchlessScreen ? 4 : 14)
            : (isNotchlessScreen ? 8 : 16)
        return CGFloat(basePadding)
    }
    
    private var leadingPadding: CGFloat {
        let basePadding = indicatorStyle == .circle
            ? (isNotchlessScreen ? 4 : 14)
            : (isNotchlessScreen ? 4 : 14)
        return CGFloat(basePadding)
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
