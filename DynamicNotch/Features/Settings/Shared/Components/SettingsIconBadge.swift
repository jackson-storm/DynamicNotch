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
    
    let tint: AnyShapeStyle
    let size: CGFloat
    let iconSize: CGFloat
    let cornerRadius: CGFloat
    let stroke: Bool 

    init(
        systemImage: String,
        tint: Color,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat,
        stroke: Bool = false
    ) {
        self.iconSource = .system(systemImage)
        self.tint = AnyShapeStyle(tint.gradient)
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
        self.stroke = stroke
    }

    init(
        imageName: String,
        tint: Color,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat,
        stroke: Bool = false
    ) {
        self.iconSource = .asset(imageName)
        self.tint = AnyShapeStyle(tint.gradient)
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
        self.stroke = stroke
    }

    init(
        systemImage: String,
        tint: AnyShapeStyle,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat,
        stroke: Bool = false
    ) {
        self.iconSource = .system(systemImage)
        self.tint = tint
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
        self.stroke = stroke
    }

    init(
        imageName: String,
        tint: AnyShapeStyle,
        size: CGFloat,
        iconSize: CGFloat,
        cornerRadius: CGFloat,
        stroke: Bool = false
    ) {
        self.iconSource = .asset(imageName)
        self.tint = tint
        self.size = size
        self.iconSize = iconSize
        self.cornerRadius = cornerRadius
        self.stroke = stroke
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint)
            .frame(width: size, height: size)
            .overlay {
                iconView
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke == false ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
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
                .scaledToFit()
                .frame(width: iconSize + 4, height: iconSize + 4)
        }
    }
}
