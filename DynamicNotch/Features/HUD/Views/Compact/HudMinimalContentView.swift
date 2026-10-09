import SwiftUI

struct HudMinimalContentView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    let image: String
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    
    var body: some View {
        HStack {
            Image(systemName: image)
                .font(.system(size: isNotchlessScreen ? 16 : 18))
                .foregroundColor(.white)
            
            Spacer()
            
            AnimatedLevelText(
                level: clampedLevel,
                fontSize: isNotchlessScreen ? 14 : 16,
                color: .white
            )
        }
        .padding(.horizontal, isNotchlessScreen ? 4.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
