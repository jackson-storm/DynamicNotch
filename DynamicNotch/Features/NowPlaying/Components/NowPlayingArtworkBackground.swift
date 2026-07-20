import SwiftUI
internal import AppKit

struct NowPlayingArtworkBackground: View {
    let artworkImage: NSImage?
    let blurRadius: CGFloat
    let darkeningOpacity: Double
    let saturation: Double
    let scale: CGFloat

    @State private var cachedResizedImage: NSImage?
    @State private var lastSourceImage: NSImage?

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
                if let displayImage = cachedResizedImage ?? artworkImage {
                    Image(nsImage: displayImage)
                        .resizable()
                        .interpolation(.low)
                        .antialiased(false)
                        .scaledToFill()
                        .frame(
                            width: proxy.size.width + blurRadius,
                            height: proxy.size.height + blurRadius
                        )
                        .scaleEffect(scale)
                        .blur(radius: blurRadius, opaque: true)
                        .saturation(saturation)
                        .opacity(darkeningOpacity)

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
            .onAppear {
                updateCachedImage()
            }
            .onChange(of: artworkImage) {
                updateCachedImage()
            }
        }
        .allowsHitTesting(false)
    }

    private func updateCachedImage() {
        guard let artworkImage else {
            cachedResizedImage = nil
            lastSourceImage = nil
            return
        }
        guard artworkImage !== lastSourceImage else { return }
        lastSourceImage = artworkImage
        
        let maxDimension: CGFloat = 80
        let targetSize: NSSize
        if artworkImage.size.width > 0 && artworkImage.size.height > 0 {
            let aspectRatio = artworkImage.size.width / artworkImage.size.height
            if aspectRatio > 1 {
                targetSize = NSSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                targetSize = NSSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        } else {
            targetSize = NSSize(width: maxDimension, height: maxDimension)
        }
        
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        artworkImage.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: artworkImage.size),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        cachedResizedImage = resized
    }
}
