internal import AppKit
import CoreImage
import SwiftUI

struct NowPlayingArtworkPalette: Equatable {
    let equalizerBaseColor: NSColor
    let equalizerHighlightColor: NSColor

    static let fallback = Self(
        equalizerBaseColor: NSColor.gray.withAlphaComponent(0.36),
        equalizerHighlightColor: NSColor.gray.withAlphaComponent(0.6)
    )

    var equalizerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: equalizerHighlightColor),
                Color(nsColor: equalizerBaseColor)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.equalizerBaseColor.isApproximatelyEqual(to: rhs.equalizerBaseColor) &&
        lhs.equalizerHighlightColor.isApproximatelyEqual(to: rhs.equalizerHighlightColor)
    }
}

enum NowPlayingArtworkPaletteExtractor {
    private static let context = CIContext()

    static func extract(from artworkData: Data?) -> NowPlayingArtworkPalette {
        guard
            let artworkData,
            let inputImage = CIImage(data: artworkData),
            let averageColor = averageColor(from: inputImage)
        else {
            return .fallback
        }

        return normalizePalette(from: averageColor)
    }

    private static func averageColor(from image: CIImage) -> NSColor? {
        let extent = image.extent.integral
        guard !extent.isEmpty else { return nil }

        let extentVector = CIVector(
            x: extent.origin.x,
            y: extent.origin.y,
            z: extent.size.width,
            w: extent.size.height
        )

        guard
            let filter = CIFilter(
                name: "CIAreaAverage",
                parameters: [
                    kCIInputImageKey: image,
                    kCIInputExtentKey: extentVector
                ]
            ),
            let outputImage = filter.outputImage
        else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: colorSpace
        )

        return NSColor(
            srgbRed: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }

    private static func normalizePalette(from color: NSColor) -> NowPlayingArtworkPalette {
        guard let resolvedColor = color.usingColorSpace(.sRGB) else {
            return .fallback
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        resolvedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        if saturation < 0.08 {
            let neutralBrightness = min(max(brightness, 0.7), 0.92)
            let neutralBase = NSColor(
                white: neutralBrightness,
                alpha: 0.72
            )
            let neutralHighlight = NSColor(
                white: min(neutralBrightness + 0.12, 1),
                alpha: 0.95
            )
            return .init(
                equalizerBaseColor: neutralBase,
                equalizerHighlightColor: neutralHighlight
            )
        }

        let normalizedSaturation = min(max(saturation * 1.12, 0.42), 0.92)
        let normalizedBrightness = min(max(brightness * 1.04, 0.58), 0.94)

        let baseColor = NSColor(
            hue: hue,
            saturation: normalizedSaturation,
            brightness: normalizedBrightness,
            alpha: 0.88
        )
        let highlightColor = NSColor(
            hue: hue,
            saturation: max(normalizedSaturation * 0.74, 0.22),
            brightness: min(normalizedBrightness + 0.12, 1),
            alpha: 1
        )

        return .init(
            equalizerBaseColor: baseColor,
            equalizerHighlightColor: highlightColor
        )
    }
}

private extension NSColor {
    func isApproximatelyEqual(to other: NSColor, tolerance: CGFloat = 0.002) -> Bool {
        guard
            let lhs = usingColorSpace(.sRGB),
            let rhs = other.usingColorSpace(.sRGB)
        else {
            return false
        }

        return abs(lhs.redComponent - rhs.redComponent) <= tolerance &&
        abs(lhs.greenComponent - rhs.greenComponent) <= tolerance &&
        abs(lhs.blueComponent - rhs.blueComponent) <= tolerance &&
        abs(lhs.alphaComponent - rhs.alphaComponent) <= tolerance
    }
}
