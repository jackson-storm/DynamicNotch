import SwiftUI

struct HudExpandedCompactContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    let image: String
    let level: Int
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                indicatorView
                
                HStack {
                    iconView
                    
                    Spacer()
                    
                    AnimatedLevelText(
                        level: clampedLevel,
                        fontSize: 14
                    )
                }
            }
        }
        .padding(.bottom, bottomPadding)
        .padding(.horizontal, horizontalPadding)
    }

    private var iconView: some View {
        Image(systemName: image)
            .font(.system(size:  16))
            .foregroundColor(.white)
    }
    
    private var indicatorView: some View {
        HudLevelIndicatorView(
            level: clampedLevel,
            indicatorStyle: .bar,
            tintStyle: indicatorTintStyle,
            showsGlow: showsIndicatorGlow,
            barWidth: 90.scaled(by: scale),
            barHeight: 8
        )
    }
    
    private var bottomPadding: CGFloat {
        isNotchlessScreen ? 12 : 12
    }
    
    private var horizontalPadding: CGFloat {
        isNotchlessScreen ? 16 : 30
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
