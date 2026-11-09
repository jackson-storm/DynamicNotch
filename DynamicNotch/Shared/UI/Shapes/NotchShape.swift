import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat
    private var horizontalPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0

    init(
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat,
        horizontalPadding: CGFloat = 0,
        bottomPadding: CGFloat = 0
    ) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.horizontalPadding = horizontalPadding
        self.bottomPadding = bottomPadding
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(
                topCornerRadius,
                bottomCornerRadius
            )
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let effectiveRect = CGRect(
            x: rect.minX + horizontalPadding,
            y: rect.minY,
            width: max(0, rect.width - horizontalPadding * 2),
            height: max(0, rect.height - bottomPadding)
        )
        guard effectiveRect.width > 0, effectiveRect.height > 0 else { return Path() }

        var path = Path()

        path.move(
            to: CGPoint(
                x: effectiveRect.minX,
                y: effectiveRect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: effectiveRect.minX + topCornerRadius,
                y: effectiveRect.minY + topCornerRadius
            ),
            control: CGPoint(
                x: effectiveRect.minX + topCornerRadius,
                y: effectiveRect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: effectiveRect.minX + topCornerRadius,
                y: effectiveRect.maxY - bottomCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: effectiveRect.minX + topCornerRadius + bottomCornerRadius,
                y: effectiveRect.maxY
            ),
            control: CGPoint(
                x: effectiveRect.minX + topCornerRadius,
                y: effectiveRect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: effectiveRect.maxX - topCornerRadius - bottomCornerRadius,
                y: effectiveRect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: effectiveRect.maxX - topCornerRadius,
                y: effectiveRect.maxY - bottomCornerRadius
            ),
            control: CGPoint(
                x: effectiveRect.maxX - topCornerRadius,
                y: effectiveRect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: effectiveRect.maxX - topCornerRadius,
                y: effectiveRect.minY + topCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: effectiveRect.maxX,
                y: effectiveRect.minY
            ),
            control: CGPoint(
                x: effectiveRect.maxX - topCornerRadius,
                y: effectiveRect.minY
            )
        )
        return path
    }
}
