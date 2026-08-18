//
//  TrayNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct TrayNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel

    private var isTargeted: Bool {
        airDropViewModel.targetedDropTarget == .tray
    }

    var body: some View {
        VStack {
            Spacer()

            TrayDropZoneContent(isTargeted: isTargeted)
                .frame(maxWidth: .infinity, maxHeight: AirDropDropZoneMetrics.height)
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}

struct TrayDropZoneContent: View {
    let isTargeted: Bool

    private var fillColor: Color {
        isTargeted ? Color.white.opacity(0.3) : Color.white.opacity(0)
    }

    private var strokeColor: Color {
        Color.white.opacity(0.4)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: AirDropDropZoneMetrics.cornerRadius)
            .fill(fillColor)
            .stroke(
                strokeColor,
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [12,6]
                )
            )
            .overlay {
                HStack {
                    VStack(spacing: 4) {
                        DragAndDropTarget.tray.icon()
                        DragAndDropTarget.tray.titleIcon()
                    }

                    Spacer()
                }
                .padding(.leading)
            }
    }
}
