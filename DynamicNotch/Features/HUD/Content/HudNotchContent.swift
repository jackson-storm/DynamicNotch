import SwiftUI

enum HudEvent: Equatable {
    case display(Int)
    case keyboard(Int)
    case volume(Int)
}

struct HudNotchContent: NotchContentProtocol {
    var id: String { kind.sharedContentID }
    var priority: Int { NotchContentPriority.default }

    let kind: HudPresentationKind
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let applicationSettings: ApplicationSettingsStore?
    
    let level: Int
    let usesColoredLevelTint: Bool
    let usesColoredLevelStroke: Bool
    
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
                return kind == .keyboard ? 150 : 140
            case .circle:
                return 140
            }
        case .compact:
            switch indicatorStyle {
            case .bar:
                return 140
            case .circle:
                return 85
            }
        case .minimal:
            return 80
        }
    }

    private var resolvedColoredLevelStroke: Bool {
        usesColoredLevelStroke && applicationSettings?.isDefaultActivityStrokeEnabled != true
    }
}
