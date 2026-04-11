import SwiftUI

struct NotchBackgroundSurface: View {
    let style: NotchBackgroundStyle
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat

    var body: some View {
        baseSurface(shape: shape)
            .contentShape(shape)
            .overlay {
                shape.stroke(strokeColor, lineWidth: strokeWidth)
            }
    }

    private var shape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    @ViewBuilder
    private func baseSurface(shape: NotchShape) -> some View {
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
