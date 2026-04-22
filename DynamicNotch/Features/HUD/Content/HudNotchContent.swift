import SwiftUI

enum HudEvent: Equatable {
    case display(Int)
    case keyboard(Int)
    case volume(Int)
}

struct HudNotchContent: NotchContentProtocol {
    var id: String { kind.sharedContentID }

    let kind: HudPresentationKind
    let level: Int
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let usesColoredLevelTint: Bool
    let usesColoredLevelStroke: Bool
    let applicationSettings: ApplicationSettingsStore?

    var offsetXTransition: CGFloat { -90 }
    
    var strokeColor: Color { HudLevelStyling.strokeTint(for: level, isEnabled: resolvedColoredLevelStroke) }

    init(
        kind: HudPresentationKind,
        level: Int,
        style: HudStyle = .standard,
        indicatorStyle: HudIndicatorStyle = .bar,
        usesColoredLevelTint: Bool = true,
        usesColoredLevelStroke: Bool = false,
        applicationSettings: ApplicationSettingsStore? = nil
    ) {
        self.kind = kind
        self.level = level
        self.style = style
        self.indicatorStyle = indicatorStyle
        self.usesColoredLevelTint = usesColoredLevelTint
        self.usesColoredLevelStroke = usesColoredLevelStroke
        self.applicationSettings = applicationSettings
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
                indicatorStyle: indicatorStyle,
                usesColoredLevelTint: usesColoredLevelTint
            )
        )
    }

    private var widthOffset: CGFloat {
        switch style {
        case .standard:
            switch indicatorStyle {
            case .bar:
                return 230
            case .circle:
                return 230
            }
        case .compact:
            switch indicatorStyle {
            case .bar:
                return 165
            case .circle:
                return 70
            }
        case .minimal:
            return 70
        }
    }

    private var resolvedColoredLevelStroke: Bool {
        usesColoredLevelStroke && applicationSettings?.isDefaultActivityStrokeEnabled != true
    }
}
