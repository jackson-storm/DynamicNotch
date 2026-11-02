import SwiftUI

/// Every row uses the same animated scroll position. Insertion/removal
/// transitions cannot give the outgoing row a stale or opposite direction.
struct HomePageScrollMotion: ViewModifier, Animatable {
    let origin: CGFloat
    let height: CGFloat
    var position: CGFloat
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func body(content: Content) -> some View {
        let offset = origin - position
        let phase = abs(offset) / max(1, height)
        content
            .blur(radius: reduceMotion ? 0 : min(20, phase * 150))
            .opacity(reduceMotion ? 1 : max(0.7, 1 - phase * 2))
            .offset(y: offset)
    }
}
