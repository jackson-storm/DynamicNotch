import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var width: Double
    var height: Double
    var cornerRadius: CGFloat = 30
    var fontSize: CGFloat = 15
    var foreground: Color = .primary
    var hoverBackground: Color = Color.secondary.opacity(0.2)

    func makeBody(configuration: Configuration) -> some View {
        CustomButtonBody(
            configuration: configuration,
            width: width,
            height: height,
            cornerRadius: cornerRadius,
            fontSize: fontSize,
            foreground: foreground,
            hoverBackground: hoverBackground
        )
    }

    private struct CustomButtonBody: View {
        let configuration: ButtonStyle.Configuration
        let width: Double
        let height: Double
        let cornerRadius: CGFloat
        let fontSize: CGFloat
        let foreground: Color
        let hoverBackground: Color

        @State private var isHovering: Bool = false

        var body: some View {
            configuration.label
                .font(.system(size: fontSize))
                .frame(width: width, height: height)
                .foregroundStyle(foreground)
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
                .scaleEffect(configuration.isPressed ? 0.80 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
                .onHover { hover in
                    isHovering = hover
                }
        }

        private var backgroundColor: Color {
            return isHovering ? hoverBackground : .clear
        }
    }
}
