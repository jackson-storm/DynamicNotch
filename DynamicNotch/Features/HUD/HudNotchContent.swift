import SwiftUI

struct HudNotchContent: NotchContentProtocol {
    var id: String { kind.sharedContentID }

    let kind: HudPresentationKind
    let level: Int
    let style: HudStyle
    let usesColoredLevelTint: Bool
    let usesColoredLevelStroke: Bool

    var offsetXTransition: CGFloat { -90 }
    var strokeColor: Color {
        HudLevelStyling.strokeTint(for: level, isEnabled: usesColoredLevelStroke)
    }

    init(
        kind: HudPresentationKind,
        level: Int,
        style: HudStyle = .standard,
        usesColoredLevelTint: Bool = true,
        usesColoredLevelStroke: Bool = false
    ) {
        self.kind = kind
        self.level = level
        self.style = style
        self.usesColoredLevelTint = usesColoredLevelTint
        self.usesColoredLevelStroke = usesColoredLevelStroke
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + widthOffset, height: baseHeight)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            HudContentView(
                image: kind.symbolName(for: level),
                text: kind.title,
                level: level,
                style: style,
                usesColoredLevelTint: usesColoredLevelTint
            )
        )
    }

    private var widthOffset: CGFloat {
        switch style {
        case .standard:
            return 230
        case .compact:
            return 165
        case .minimal:
            return 70
        }
    }
}
