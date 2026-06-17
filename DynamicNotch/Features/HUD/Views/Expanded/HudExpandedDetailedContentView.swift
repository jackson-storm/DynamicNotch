import SwiftUI

struct HudExpandedDetailedContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    let image: String
    let text: String
    let level: Int
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 10) {
                deviceName
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
        }
        .padding(.bottom, bottomPadding)
        .padding(.horizontal, horizontalPadding)
    }
    
    private var deviceName: some View {
        MarqueeText(
            .constant(text),
            font: .system(size: 15, design: .rounded),
            nsFont: .body,
            textColor: .white.opacity(0.9),
            backgroundColor: .clear,
            minDuration: 1.5,
            frameWidth: 175
        )
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
        isDynamicIsland ? 14 : 14
    }
    
    private var horizontalPadding: CGFloat {
        isDynamicIsland ? 24 : 34
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
