import SwiftUI

struct NotchBackgroundSurface: View {
    let style: NotchBackgroundStyle
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isDynamicIsland: Bool
    var usesTopAttachedShape: Bool = false
    let dynamicIslandCornerRadius: CGFloat
    let strokeColor: Color
    var strokeWidth: CGFloat = 2.5
    var height: CGFloat? = nil
    var baseHeight: CGFloat? = nil
    
    var effectiveStrokeWidth: CGFloat {
        Self.resolvedStrokeWidth(
            baseHeight: baseHeight,
            height: height,
            defaultStrokeWidth: strokeWidth
        )
    }

    static func resolvedStrokeWidth(
        baseHeight: CGFloat?,
        height: CGFloat?,
        defaultStrokeWidth: CGFloat = 2.5
    ) -> CGFloat {
        if let baseHeight, let height, baseHeight > height {
            return 2.0
        }
        return defaultStrokeWidth
    }
    
    var body: some View {
        if isDynamicIsland && !usesTopAttachedShape {
            let shape = DynamicIslandShape(cornerRadius: dynamicIslandCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: effectiveStrokeWidth)
                }
        } else if usesTopAttachedShape {
            let shape = TopAttachedNotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: effectiveStrokeWidth)
                }
        } else {
            let shape = NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
            baseSurface(shape: shape)
                .contentShape(shape)
                .overlay {
                    shape.stroke(strokeColor, lineWidth: effectiveStrokeWidth)
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
