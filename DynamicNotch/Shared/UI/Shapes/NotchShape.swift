import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat

    init(
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat
    ) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
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
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY + topCornerRadius
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius + bottomCornerRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius - bottomCornerRadius,
                y: rect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY + topCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY
            )
        )
        return path
    }
}

struct TopAttachedNotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat
    private var topOutset: CGFloat

    init(
        topCornerRadius: CGFloat,
        bottomCornerRadius: CGFloat,
        topOutset: CGFloat? = nil
    ) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.topOutset = topOutset ?? topCornerRadius
    }

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get {
            .init(
                .init(topCornerRadius, bottomCornerRadius),
                topOutset
            )
        }
        set {
            topCornerRadius = newValue.first.first
            bottomCornerRadius = newValue.first.second
            topOutset = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let topRadius = min(max(0, topCornerRadius), rect.height)
        let bottomRadius = min(max(0, bottomCornerRadius), rect.height)
        let shoulderOutset = max(0, topOutset)

        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX - shoulderOutset,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX + shoulderOutset,
                y: rect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY + topRadius
            ),
            control: CGPoint(
                x: rect.maxX,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY - bottomRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - bottomRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.maxX,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + bottomRadius,
                y: rect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX,
                y: rect.maxY - bottomRadius
            ),
            control: CGPoint(
                x: rect.minX,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY + topRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX - shoulderOutset,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        return path
    }
}

