import Foundation
import CoreGraphics

nonisolated enum HomePageNavigationLayout {
    /// Keep the pointer inside the panel while navigating to a smaller page.
    /// Location is measured from the current panel's top-left corner.
    static func minimumSize(size: CGSize, pointer: CGPoint) -> CGSize {
        guard size.width > 0, size.height > 0,
              pointer.x.isFinite, pointer.y.isFinite,
              CGRect(origin: .zero, size: size).contains(pointer) else { return .zero }
        return CGSize(width: abs(pointer.x - size.width / 2) * 2 + 48, height: pointer.y + 24)
    }

    static func expandedSize(preferred: CGSize, minimum: CGSize) -> CGSize {
        CGSize(width: max(preferred.width, minimum.width), height: max(preferred.height, minimum.height))
    }
}
