import SwiftUI

struct BlurFadeModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
            .compositingGroup()
    }
}

extension AnyTransition {
    static var blurAndFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 20, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }
}
