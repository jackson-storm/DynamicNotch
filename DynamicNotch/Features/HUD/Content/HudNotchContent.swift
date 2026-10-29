import SwiftUI

enum HudEvent: Equatable {
    case display(Int)
    case keyboard(Int)
    case volume(level: Int, deviceName: String?)

    static func volume(_ level: Int) -> HudEvent {
        return .volume(level: level, deviceName: nil)
    }
}

struct HudNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    var id: String { kind.sharedContentID }
    var priority: Int { NotchContentPriority.default }

    let kind: HudPresentationKind
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let applicationSettings: ApplicationSettingsStore?
    
    let level: Int
    let deviceName: String?
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    let usesColoredLevelStroke: Bool
    
    var strokeColor: Color { HudLevelStyling.strokeTint(for: level, isEnabled: usesColoredLevelStroke) }

    init(
        kind: HudPresentationKind,
        level: Int,
        style: HudStyle = .compact,
        indicatorStyle: HudIndicatorStyle = .bar,
        indicatorTintStyle: HudIndicatorTintStyle = .levelColor,
        showsIndicatorGlow: Bool = true,
        usesColoredLevelStroke: Bool = false,
        deviceName: String? = nil,
        applicationSettings: ApplicationSettingsStore? = nil
    ) {
        self.kind = kind
        self.level = level
        self.style = style
        self.indicatorStyle = indicatorStyle
        self.indicatorTintStyle = indicatorTintStyle
        self.showsIndicatorGlow = showsIndicatorGlow
        self.usesColoredLevelStroke = usesColoredLevelStroke
        self.deviceName = deviceName
        self.applicationSettings = applicationSettings
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        if isStyleExpanded {
            return (top: baseRadius + 6, bottom: baseRadius + 10)
        } else {
            return (top: baseRadius - 4, bottom: baseRadius)
        }
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        if style == .expandedDetailed {
            return baseHeight * 0.3
        } else {
            return baseHeight * 0.5
        }
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = isStyleExpanded ? baseWidth + 20 : baseWidth + widthOffset
        let height = isStyleExpanded ? baseHeight + heightOffset : baseHeight
        
        return .init(width: width, height: height)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = isStyleExpanded ? baseWidth + 130 : baseWidth + dynamicIslandWidthOffset
        let height = isStyleExpanded ? baseHeight + heightOffset : baseHeight
        
        return .init(width: width, height: height)
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            HudContentView(
                kind: kind,
                image: kind.symbolName(for: level),
                text: deviceName ?? kind.title,
                level: level,
                style: style,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        )
    }

    private var isStyleExpanded: Bool {
        style == .expandedCompact || style == .expandedDetailed
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
            
        case .expandedCompact:
            return 85
            
        case .expandedDetailed:
            return 85
        }
    }
    
    private var dynamicIslandWidthOffset: CGFloat {
        switch style {
        case .standard:
            switch indicatorStyle {
            case .bar:
                return kind == .keyboard ? 140 : 130
            case .circle:
                return 125
            }
            
        case .compact:
            switch indicatorStyle {
            case .bar:
                return 130
            case .circle:
                return 60
            }
            
        case .minimal:
            return 75
            
        case .expandedCompact:
            return 85
            
        case .expandedDetailed:
            return 85
        }
    }
    
    private var heightOffset: CGFloat {
        switch style {
        case .standard:
            return 0
        case .compact:
            return 0
        case .minimal:
            return 0
        case .expandedCompact:
            return 35
        case .expandedDetailed:
            return 65
        }
    }
}
