import SwiftUI

struct HudContentView: View {
    let kind: HudPresentationKind
    let image: String
    let text: String
    let level: Int
    let style: HudStyle
    let indicatorStyle: HudIndicatorStyle
    let indicatorTintStyle: HudIndicatorTintStyle
    let showsIndicatorGlow: Bool
    
    var body: some View {
        switch style {
        case .standard:
            HudStandardContentView(
                kind: kind,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .compact:
            HudCompactContentView(
                image: image,
                level: level,
                indicatorStyle: indicatorStyle,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .minimal:
            HudMinimalContentView(
                image: image,
                level: level,
                indicatorStyle: indicatorStyle
            )
        case .expandedCompact:
            HudExpandedCompactContentView(
                image: image,
                level: level,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        case .expandedDetailed:
            HudExpandedDetailedContentView(
                image: image,
                text: text,
                level: level,
                indicatorTintStyle: indicatorTintStyle,
                showsIndicatorGlow: showsIndicatorGlow
            )
        }
    }
}


