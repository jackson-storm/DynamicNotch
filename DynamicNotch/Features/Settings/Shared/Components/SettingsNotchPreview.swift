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
    let previewHeight: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let showsStroke: Bool
    let strokeColor: Color
    let strokeWidth: CGFloat

    private let overlay: Overlay

    init(
        width: CGFloat = 370,
        height: CGFloat = 38,
        previewHeight: CGFloat = 138,
        topCornerRadius: CGFloat = 9,
        bottomCornerRadius: CGFloat = 13,
        showsStroke: Bool = true,
        strokeColor: Color = .green.opacity(0.3),
        strokeWidth: CGFloat = 1.5,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.width = width
        self.height = height
        self.previewHeight = previewHeight
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
        self.showsStroke = showsStroke
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.overlay = overlay()
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .frame(height: previewHeight)

            NotchShape(
                topCornerRadius: topCornerRadius,
                bottomCornerRadius: bottomCornerRadius
            )
            .fill(.black)
            .overlay {
                NotchShape(
                    topCornerRadius: topCornerRadius,
                    bottomCornerRadius: bottomCornerRadius
                )
                .stroke(
                    showsStroke ? strokeColor : .clear,
                    lineWidth: strokeWidth
                )
            }
            .overlay {
                overlay
            }
            .frame(width: width, height: height)
        }
    }
}
