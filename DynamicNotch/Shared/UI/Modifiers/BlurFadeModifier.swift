import SwiftUI

enum DynamicIslandTransitionMetrics {
    static let horizontalCompensationRatio: CGFloat = 3.0 / 13.0

    static func horizontalCompensationOffset(for notchWidth: CGFloat) -> CGFloat {
        -(max(0, notchWidth) * horizontalCompensationRatio)
    }

    static func verticalCompensationOffset(for notchHeight: CGFloat, baseHeight: CGFloat) -> CGFloat {
        -(max(0, notchHeight - baseHeight) / 2)
    }
}

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

private struct DynamicIslandTransitionModifier: ViewModifier {
    var blur: CGFloat = 0
    var opacity: Double = 1
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: scaleX, y: scaleY, anchor: anchor)
            .offset(x: offsetX, y: offsetY)
            .blur(radius: blur)
            .opacity(opacity)
            .compositingGroup()
    }
}

extension AnyTransition {
    static var blurAndFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 40, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }

    static func dynamicIslandContent(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat, isExpandedPresentation: Bool) -> AnyTransition {
        if isExpandedPresentation {
            return dynamicIslandExpanded(
                notchWidth: notchWidth,
                notchHeight: notchHeight,
                baseHeight: baseHeight
            )
        }
        return dynamicIslandCompact(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseHeight: baseHeight
        )
    }

    private static func dynamicIslandCompact(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat) -> AnyTransition {
        let horizontalOffset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: notchWidth)
        let verticalOffset = DynamicIslandTransitionMetrics.verticalCompensationOffset(
            for: notchHeight,
            baseHeight: baseHeight
        )

        return .asymmetric(
            insertion: .modifier(
                active: DynamicIslandTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
                    offsetY: verticalOffset,
                    scaleX: 0.4,
                    scaleY: 0.6,
                    anchor: .center
                ),
                identity: DynamicIslandTransitionModifier(anchor: .center)
            ),
            removal: .modifier(
                active: DynamicIslandTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
                    offsetY: verticalOffset,
                    scaleX: 0.4,
                    scaleY: 0.6,
                    anchor: .center
                ),
                identity: DynamicIslandTransitionModifier(anchor: .center)
            )
        )
    }

    private static func dynamicIslandExpanded(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat) -> AnyTransition {
        let horizontalOffset = DynamicIslandTransitionMetrics.horizontalCompensationOffset(for: notchWidth)
        let verticalOffset = DynamicIslandTransitionMetrics.verticalCompensationOffset(
            for: notchHeight,
            baseHeight: baseHeight
        )

        return .asymmetric(
            insertion: .modifier(
                active: DynamicIslandTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
                    offsetY: verticalOffset / 3,
                    scaleX: 0.4,
                    scaleY: 0.6,
                    anchor: .top
                ),
                identity: DynamicIslandTransitionModifier(anchor: .top)
            ),
            removal: .modifier(
                active: DynamicIslandTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
                    offsetY: verticalOffset / 3,
                    scaleX: 0.4,
                    scaleY: 0.6,
                    anchor: .top
                ),
                identity: DynamicIslandTransitionModifier(anchor: .top)
            )
        )
    }
}
