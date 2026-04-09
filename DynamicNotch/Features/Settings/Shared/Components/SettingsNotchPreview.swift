//
//  NotchPreview.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsNotchPreview<Overlay: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let width: CGFloat
    let height: CGFloat
    let previewWidth: CGFloat
    let previewHeight: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let backgroundStyle: NotchBackgroundStyle
    let showsStroke: Bool
    let strokeColor: Color
    let strokeWidth: CGFloat
    let lightBackgroundImage: Image?
    let darkBackgroundImage: Image?
    let backgroundImageContentMode: ContentMode
    let backgroundImageOpacity: Double
    
    private let overlay: Overlay
    
    init(
        width: CGFloat = 370,
        height: CGFloat = 38,
        previewWidth: CGFloat = .infinity,
        previewHeight: CGFloat = 138,
        topCornerRadius: CGFloat = 9,
        bottomCornerRadius: CGFloat = 13,
        backgroundStyle: NotchBackgroundStyle = .black,
        showsStroke: Bool = true,
        strokeColor: Color = .green.opacity(0.3),
        strokeWidth: CGFloat = 1.5,
        lightBackgroundImage: Image? = nil,
        darkBackgroundImage: Image? = nil,
        backgroundImageContentMode: ContentMode = .fill,
        backgroundImageOpacity: Double = 1,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.width = width
        self.height = height
        self.previewWidth = previewWidth
        self.previewHeight = previewHeight
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.backgroundStyle = backgroundStyle
        self.showsStroke = showsStroke
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.lightBackgroundImage = lightBackgroundImage
        self.darkBackgroundImage = darkBackgroundImage
        self.backgroundImageContentMode = backgroundImageContentMode
        self.backgroundImageOpacity = backgroundImageOpacity
        self.overlay = overlay()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))

                    previewBackgroundImage(size: proxy.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            }
            
            notchSurface
                .overlay {
                    overlay
                }
                .environment(\.colorScheme, .dark)
                .frame(width: width, height: height)
        }
        .frame(maxWidth: previewWidth)
        .frame(height: previewHeight, alignment: .top)
        .clipped()
    }

    @ViewBuilder
    private func previewBackgroundImage(size: CGSize) -> some View {
        if colorScheme == .light {
            if let lightBackgroundImage {
                lightBackgroundImage
                    .resizable()
                    .aspectRatio(contentMode: backgroundImageContentMode)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(backgroundImageOpacity)
            }
        } else if let darkBackgroundImage {
            darkBackgroundImage
                .resizable()
                .aspectRatio(contentMode: backgroundImageContentMode)
                .frame(width: size.width, height: size.height)
                .clipped()
                .opacity(backgroundImageOpacity)
        }
    }
    
    @ViewBuilder
    private var notchSurface: some View {
        NotchBackgroundSurface(
            style: backgroundStyle,
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius,
            strokeColor: showsStroke ? strokeColor : .clear,
            strokeWidth: strokeWidth
        )
    }
}
