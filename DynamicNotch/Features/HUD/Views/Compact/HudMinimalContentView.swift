import SwiftUI

struct HudMinimalContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    let image: String
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            Spacer()
            AnimatedLevelText(
                level: clampedLevel,
                fontSize: isNotchlessScreen ? 14 : 16
            )
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }
    
    private var iconView: some View {
        Image(systemName: image)
            .font(.system(size: isNotchlessScreen ? 16 : 18))
            .foregroundColor(.white)
    }
    
    private var verticalPadding: CGFloat {
        10
    }
    
    private var horizontalPadding: CGFloat {
        let basePadding = indicatorStyle == .circle
            ? (isNotchlessScreen ? 4 : 14)
            : (isNotchlessScreen ? 4 : 14)
        return basePadding.scaled(by: scale)
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
