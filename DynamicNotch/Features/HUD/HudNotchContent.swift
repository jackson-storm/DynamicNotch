import SwiftUI

struct HudNotchContent: NotchContentProtocol {
    var id: String { kind.sharedContentID }

    let kind: HudPresentationKind
    let level: Int

    var offsetXTransition: CGFloat { -90 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 220, height: baseHeight)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            HudContentView(
                image: kind.symbolName(for: level),
                text: kind.title,
                level: level
            )
        )
    }
}
