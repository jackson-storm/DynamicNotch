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
    let сornerRadius: CGFloat
    let strokeColor: Color
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
        сornerRadius: CGFloat = 20,
        strokeColor: Color = .white.opacity(0.2),
        strokeWidth: CGFloat = 2.5,
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
        self.сornerRadius = сornerRadius
        self.strokeColor = strokeColor
        self.lightBackgroundImage = lightBackgroundImage
        self.darkBackgroundImage = darkBackgroundImage
        self.backgroundImageContentMode = backgroundImageContentMode
        self.backgroundImageOpacity = backgroundImageOpacity
        self.overlay = overlay()
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))

                    previewBackgroundImage(size: proxy.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            RoundedRectangle(cornerRadius: сornerRadius)
                .fill(.black)
                .stroke(strokeColor, lineWidth: 2.5)
                .overlay {
                    overlay
                }
                .environment(\.colorScheme, .dark)
                .frame(width: width, height: height)
        }
        .frame(maxWidth: previewWidth)
        .frame(height: previewHeight, alignment: .center)
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
}
