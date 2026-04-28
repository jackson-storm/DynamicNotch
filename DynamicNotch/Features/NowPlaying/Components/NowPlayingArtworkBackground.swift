import SwiftUI
internal import AppKit

struct NowPlayingArtworkBackground: View {
    let artworkImage: NSImage?
    let blurRadius: CGFloat
    let darkeningOpacity: Double
    let saturation: Double
    let scale: CGFloat

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
                if let artworkImage {
                    Image(nsImage: artworkImage)
                        .resizable()
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
        }
        .allowsHitTesting(false)
    }
}
