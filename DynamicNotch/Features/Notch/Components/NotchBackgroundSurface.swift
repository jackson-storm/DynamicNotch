import SwiftUI

struct NotchBackgroundSurface: View {
    let style: NotchBackgroundStyle
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let isDynamicIsland: Bool
    let dynamicIslandCornerRadius: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    let liquidGlassVariant: Int
    var height: CGFloat? = nil
    var baseHeight: CGFloat? = nil
    
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
            LiquidGlassBackground(
                variant: LiquidGlassVariant.clamped(liquidGlassVariant),
                cornerRadius: isDynamicIsland ? dynamicIslandCornerRadius : 0
            ) {
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.4),
                            .init(color: .black, location: 0.6),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    if let height, let baseHeight, height > baseHeight {
                        // Only vertical gradient
                    } else {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black, location: 0.25),
                                .init(color: .black, location: 0.75),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            }
            .clipShape(shape)
        }
    }
}
