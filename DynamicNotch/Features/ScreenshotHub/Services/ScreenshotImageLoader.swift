internal import AppKit
import ImageIO

nonisolated enum ScreenshotImageLoader {
    /// Long side of the preview in pixels. The flight draws the image at most 360 pt wide
    /// (720 px on a 2x display) and the notch shows it at 50 pt, so 1024 px covers both.
    static let previewMaxPixelSize: CGFloat = 1024

    /// It decodes only the preview. The full image stays lazy, so a 20 MP screenshot costs one
    /// reduced decode before the flight instead of a full decode plus a reduced decode.
    /// screencapture renames a finished file into place. Thus, a file under its final name is
    /// complete.
    static func load(contentsOf url: URL, previewMaxPixelSize: CGFloat) -> (image: NSImage, preview: NSImage)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              CGImageSourceGetCount(source) > 0,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let fullPixelWidth = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let fullPixelHeight = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
              fullPixelWidth > 0, fullPixelHeight > 0,
              let previewImage = CGImageSourceCreateThumbnailAtIndex(
                  source,
                  0,
                  [
                      kCGImageSourceCreateThumbnailFromImageAlways: true,
                      kCGImageSourceThumbnailMaxPixelSize: previewMaxPixelSize,
                      kCGImageSourceCreateThumbnailWithTransform: true,
                      kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary
              ),
              let fullImage = NSImage(contentsOf: url) else {
            return nil
        }

        let pointsPerPixel = pointsPerPixel(from: properties)
        let fullSize = NSSize(
            width: fullPixelWidth * pointsPerPixel.width,
            height: fullPixelHeight * pointsPerPixel.height
        )
        let previewSize = scaledSize(
            of: fullSize,
            toPixelWidth: CGFloat(previewImage.width),
            pixelHeight: CGFloat(previewImage.height),
            fullPixelWidth: fullPixelWidth,
            fullPixelHeight: fullPixelHeight
        )

        return (fullImage, NSImage(cgImage: previewImage, size: previewSize))
    }

    static func makePreview(from image: NSImage, maxPixelSize: CGFloat) -> NSImage {
        let pixelSize = largestPixelSize(of: image)
        guard pixelSize.width > 0, pixelSize.height > 0 else { return image }

        let factor = min(1.0, maxPixelSize / max(pixelSize.width, pixelSize.height))
        let targetWidth = max(1, Int((pixelSize.width * factor).rounded()))
        let targetHeight = max(1, Int((pixelSize.height * factor).rounded()))

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetWidth,
            pixelsHigh: targetHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return image
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(
            in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        let previewSize = scaledSize(
            of: image.size,
            toPixelWidth: CGFloat(targetWidth),
            pixelHeight: CGFloat(targetHeight),
            fullPixelWidth: pixelSize.width,
            fullPixelHeight: pixelSize.height
        )
        bitmap.size = previewSize
        let preview = NSImage(size: previewSize)
        preview.addRepresentation(bitmap)
        return preview
    }

    private static func pointsPerPixel(from properties: [CFString: Any]?) -> CGSize {
        let dpiWidth = (properties?[kCGImagePropertyDPIWidth] as? NSNumber)?.doubleValue ?? 72
        let dpiHeight = (properties?[kCGImagePropertyDPIHeight] as? NSNumber)?.doubleValue ?? 72
        return CGSize(
            width: dpiWidth > 0 ? 72 / dpiWidth : 1,
            height: dpiHeight > 0 ? 72 / dpiHeight : 1
        )
    }

    private static func scaledSize(
        of pointSize: NSSize,
        toPixelWidth pixelWidth: CGFloat,
        pixelHeight: CGFloat,
        fullPixelWidth: CGFloat,
        fullPixelHeight: CGFloat
    ) -> NSSize {
        guard fullPixelWidth > 0, fullPixelHeight > 0 else { return pointSize }
        return NSSize(
            width: pointSize.width * pixelWidth / fullPixelWidth,
            height: pointSize.height * pixelHeight / fullPixelHeight
        )
    }

    private static func largestPixelSize(of image: NSImage) -> CGSize {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return CGSize(width: cgImage.width, height: cgImage.height)
        }
        return image.size
    }
}
