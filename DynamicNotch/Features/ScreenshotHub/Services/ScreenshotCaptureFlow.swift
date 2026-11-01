import Foundation
import CoreGraphics

enum ScreenshotCaptureFlow {
    @MainActor
    static func run<Selection, Image>(
        hide: () -> Void,
        restore: () -> Void,
        select: () async throws -> Selection?,
        capture: (Selection) async throws -> Image,
        copy: (Image) throws -> Void
    ) async throws -> Bool {
        hide()
        defer { restore() }
        guard let selection = try await select() else { return false }
        let image = try await capture(selection)
        try copy(image)
        return true
    }
}

struct ScreenshotCaptureGeometry {
    let sourceRect: CGRect
    let pixelWidth: Int
    let pixelHeight: Int

    init(screenFrame: CGRect, scale: CGFloat, selection: CGRect? = nil) {
        let region = (selection ?? screenFrame).intersection(screenFrame)
        guard !region.isNull, !region.isEmpty, scale.isFinite, scale > 0 else {
            sourceRect = .zero
            pixelWidth = 0
            pixelHeight = 0
            return
        }
        sourceRect = CGRect(
            x: region.minX - screenFrame.minX,
            y: screenFrame.maxY - region.maxY,
            width: region.width,
            height: region.height
        )
        pixelWidth = max(1, Int((region.width * scale).rounded(.up)))
        pixelHeight = max(1, Int((region.height * scale).rounded(.up)))
    }
}
