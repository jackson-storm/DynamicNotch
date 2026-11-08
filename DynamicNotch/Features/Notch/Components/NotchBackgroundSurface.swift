import SwiftUI

struct NotchBackgroundSurface: View {
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isDynamicIsland: Bool
    let dynamicIslandCornerRadius: CGFloat
    let strokeColor: Color
    var strokeWidth: CGFloat = 2.0
    var height: CGFloat? = nil
    var baseWidth: CGFloat? = nil
    var baseHeight: CGFloat? = nil
    
    var body: some View {
        if isDynamicIsland {
            let shape = DynamicIslandShape(cornerRadius: dynamicIslandCornerRadius)
            shape
                .fill(.black)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: strokeWidth)
                }
        } else {
            let shape = NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
            shape
                .fill(.black)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: strokeWidth)
                }
        }
    }
}
