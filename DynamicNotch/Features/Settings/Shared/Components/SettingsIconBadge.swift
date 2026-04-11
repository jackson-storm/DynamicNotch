//
//  SettingsIconBadge.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsIconBadge: View {
    private enum IconSource {
        case system(String)
        case asset(String)
    }

    private let iconSource: IconSource
    let tint: Color
    let size: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat

    init(
        systemImage: String,
        tint: Color,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat
    ) {
        self.iconSource = .system(systemImage)
        self.tint = tint
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }

    init(
        imageName: String,
        tint: Color,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat
    ) {
        self.iconSource = .asset(imageName)
        self.tint = tint
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay {
                iconView
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            }
    }

    @ViewBuilder
    private var iconView: some View {
        switch iconSource {
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)

        case .asset(let imageName):
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.white)
                .scaledToFit()
                .frame(width: iconSize + 4, height: iconSize + 4)
        }
    }
}
