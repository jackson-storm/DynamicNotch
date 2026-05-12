//
//  DragAndDropDropZoneView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

enum AirDropDropZoneMetrics {
    static let cornerRadius: CGFloat = 18
    static let width: CGFloat = .infinity
    static let height: CGFloat = 90
    static let horizontalPadding: CGFloat = 40
    static let verticalPadding: CGFloat = 16
    static let combinedSpacing: CGFloat = 12
}

struct DragAndDropDropZoneView: View {
    let target: DragAndDropTarget
    let isTargeted: Bool
    var targetColorStyle: DragAndDropTargetColorStyle = .original

    var body: some View {
        VStack {
            Spacer()

            DragAndDropDropZoneContent(
                target: target,
                isTargeted: isTargeted,
                targetColorStyle: targetColorStyle
            )
                .frame(maxWidth: .infinity, maxHeight: AirDropDropZoneMetrics.height)
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}

struct DragAndDropDropZoneContent: View {
    let target: DragAndDropTarget
    let isTargeted: Bool
    var targetColorStyle: DragAndDropTargetColorStyle = .original

    private var targetColor: Color {
        target.color(for: targetColorStyle)
    }

    private var strokeColor: Color {
        targetColor.opacity(0.6)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: AirDropDropZoneMetrics.cornerRadius)
            .fill(isTargeted ? targetColor.opacity(0.2) : .clear.opacity(0))
            .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [18, 10]))
            .overlay {
                VStack(spacing: 4) {
                    target.icon(colorStyle: targetColorStyle)
                    target.titleIcon(colorStyle: targetColorStyle)
                }
                .foregroundStyle(targetColor)
            }
    }
}
