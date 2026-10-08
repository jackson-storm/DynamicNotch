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
                HudLevelIndicatorView(
                    level: clampedLevel,
                    indicatorStyle: .bar,
                    tintStyle: indicatorTintStyle,
                    showsGlow: showsIndicatorGlow,
                    barWidth: 90.scaled(by: scale),
                    barHeight: 8
                )
                
                HStack {
                    Image(systemName: image)
                        .font(.system(size:  16))
                        .foregroundColor(.white)
                    
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
