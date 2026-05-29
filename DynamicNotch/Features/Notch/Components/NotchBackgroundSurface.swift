import SwiftUI

struct NotchBackgroundSurface: View {
    let style: NotchBackgroundStyle
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isDynamicIsland: Bool
    let dynamicIslandCornerRadius: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    var body: some View {
        if isDynamicIsland {
            let shape = DynamicIslandShape(cornerRadius: dynamicIslandCornerRadius)
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
            
        case .ultraThickMaterial:
            shape.fill(.ultraThinMaterial)
            
        case .liquidGlass:
            ZStack {
                shape.fill(Color.white.opacity(0.001))
                
                if #available(macOS 26.0, *) {
                    Color.clear
                        .glassEffect(.regular, in: shape)
                }
            }
        }
    }
}
