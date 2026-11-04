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
                fontSize: isNotchlessScreen ? 14 : 15,
                color: .white
            )
        }
        .padding(.leading, isNotchlessScreen ? 5.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 7.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var clampedLevel: Int {
        max(0, min(100, level))
    }
}
