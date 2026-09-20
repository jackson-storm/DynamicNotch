import SwiftUI

struct NotchBackgroundSurface: View {
    let style: NotchBackgroundStyle
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isDynamicIsland: Bool
    var usesTopAttachedShape: Bool = false
    let dynamicIslandCornerRadius: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    var height: CGFloat? = nil
    var baseHeight: CGFloat? = nil
    
    var body: some View {
        if isDynamicIsland && !usesTopAttachedShape {
            let shape = DynamicIslandShape(cornerRadius: dynamicIslandCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: strokeWidth)
                }
        } else if usesTopAttachedShape {
            let shape = TopAttachedNotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: strokeWidth)
                }
        } else {
            let shape = NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: strokeWidth)
                }
        }
    }
    
    @ViewBuilder
    private func baseSurface<S: Shape>(shape: S) -> some View {
        switch style {
        case .black:
            shape.fill(.black)
        }
    }
}
