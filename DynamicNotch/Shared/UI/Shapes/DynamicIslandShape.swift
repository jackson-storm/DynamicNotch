import SwiftUI

struct DynamicIslandShape: Shape {
    var cornerRadius: CGFloat
    var horizontalPadding: CGFloat = 0
    var verticalPadding: CGFloat = 0

    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let insetRect = CGRect(
            x: rect.minX + horizontalPadding,
            y: rect.minY + verticalPadding,
            width: max(0, rect.width - horizontalPadding * 2),
            height: max(0, rect.height - verticalPadding * 2)
        )
        guard insetRect.width > 0, insetRect.height > 0 else { return path }
        let maxRadius = min(insetRect.width, insetRect.height) * 0.5
        let clampedRadius = max(0, min(cornerRadius, maxRadius))
        path.addRoundedRect(in: insetRect, cornerSize: CGSize(width: clampedRadius, height: clampedRadius))
        return path
    }
}
