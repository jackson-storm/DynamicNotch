import SwiftUI
internal import AppKit
import CoreImage

struct NowPlayingArtworkBackground: View {
    let artworkImage: NSImage?
    let blurRadius: CGFloat
    let darkeningOpacity: Double
    let saturation: Double
    let scale: CGFloat

    @State private var bakedBlurredImage: NSImage?

    init(
        artworkImage: NSImage?,
        blurRadius: CGFloat = 34,
        darkeningOpacity: Double = 0.68,
        saturation: Double = 1.35,
        scale: CGFloat = 1.24
    ) {
        self.artworkImage = artworkImage
        self.blurRadius = blurRadius
        self.darkeningOpacity = darkeningOpacity
        self.saturation = saturation
        self.scale = scale
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let displayImage = bakedBlurredImage {
                    Image(nsImage: displayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(scale)
                        .opacity(darkeningOpacity)
                        .transition(.opacity)

                    LinearGradient(
                        colors: [
                            .white.opacity(0.08),
                            .black.opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.softLight)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: artworkImage) {
                await processArtwork(artworkImage)
            }
        }
        .allowsHitTesting(false)
    }

    @MainActor
    private func processArtwork(_ sourceImage: NSImage?) async {
        guard let sourceImage else {
            bakedBlurredImage = nil
            return
        }

        let blurred = NowPlayingArtworkBlurProcessor.generateBlurredImage(
            from: sourceImage,
            blurRadius: blurRadius,
            saturation: saturation
        )

        withAnimation(.easeInOut(duration: 0.35)) {
            self.bakedBlurredImage = blurred
        }
    }
}

@MainActor
private enum NowPlayingArtworkBlurProcessor {
    private static let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: true
    ])
    private static let cache = NSCache<NSString, NSImage>()

    static func generateBlurredImage(
        from image: NSImage,
        blurRadius: CGFloat,
        saturation: Double
    ) -> NSImage? {
        let cacheKey = NSString(format: "%p_%.1f_%.2f", image, blurRadius, saturation)
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) ?? createCGImageFallback(from: image) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }

        let maxDimension: CGFloat = 160
        let scaleFactor = min(maxDimension / extent.width, maxDimension / extent.height)
        let targetExtent = CGRect(
            x: 0,
            y: 0,
            width: max(1, extent.width * scaleFactor),
            height: max(1, extent.height * scaleFactor)
        )

        let downscaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let clamped = downscaled.clampedToExtent()

        // Blur radius proportional to downscaled resolution
        let effectiveBlurRadius = max(8.0, blurRadius * (maxDimension / 1000.0))

        var processedImage: CIImage = clamped
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(clamped, forKey: kCIInputImageKey)
            blurFilter.setValue(effectiveBlurRadius, forKey: kCIInputRadiusKey)
            if let output = blurFilter.outputImage {
                processedImage = output
            }
        }

        if saturation != 1.0, let satFilter = CIFilter(name: "CIColorControls") {
            satFilter.setValue(processedImage, forKey: kCIInputImageKey)
            satFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            if let output = satFilter.outputImage {
                processedImage = output
            }
        }

        let cropped = processedImage.cropped(to: targetExtent)
        guard let outputCGImage = ciContext.createCGImage(cropped, from: targetExtent) else {
            return nil
        }

        let result = NSImage(cgImage: outputCGImage, size: targetExtent.size)
        cache.setObject(result, forKey: cacheKey)
        return result
    }

    private static func createCGImageFallback(from image: NSImage) -> CGImage? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.cgImage
    }
}
