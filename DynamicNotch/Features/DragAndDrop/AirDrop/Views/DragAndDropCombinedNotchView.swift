//
//  DragAndDropCombinedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct DragAndDropCombinedNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    
    let isMotionAnimationEnabled: Bool

    var body: some View {
        if isMotionAnimationEnabled {
            motionLayout
        } else {
            staticLayout
        }
    }

    private var motionLayout: some View {
        GeometryReader { proxy in
            let spacing = AirDropDropZoneMetrics.combinedSpacing
            let horizontalPadding = AirDropDropZoneMetrics.horizontalPadding
            let availableWidth = max(proxy.size.width - (horizontalPadding * 2) - spacing, 0)
            let isAirDropTargeted = airDropViewModel.targetedDropTarget == .airDrop
            let isTrayTargeted = airDropViewModel.targetedDropTarget == .tray
            let expandedPortion: CGFloat = 0.65
            let equalPortion: CGFloat = 0.5
            let airDropWidth = isAirDropTargeted ? availableWidth * expandedPortion : (isTrayTargeted ? availableWidth * (1 - expandedPortion) : availableWidth * equalPortion)
            let trayWidth = availableWidth - airDropWidth

            VStack {
                Spacer()

                HStack(spacing: spacing) {
                    DragAndDropDropZoneContent(
                        target: .airDrop,
                        isTargeted: isAirDropTargeted
                    )
                    .frame(width: airDropWidth, height: AirDropDropZoneMetrics.height)

                    DragAndDropDropZoneContent(
                        target: .tray,
                        isTargeted: isTrayTargeted
                    )
                    .frame(width: trayWidth, height: AirDropDropZoneMetrics.height)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: airDropViewModel.targetedDropTarget)
        }
    }

    private var staticLayout: some View {
        VStack {
            Spacer()

            HStack(spacing: AirDropDropZoneMetrics.combinedSpacing) {
                DragAndDropDropZoneContent(
                    target: .airDrop,
                    isTargeted: airDropViewModel.targetedDropTarget == .airDrop
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: AirDropDropZoneMetrics.height,
                    maxHeight: AirDropDropZoneMetrics.height
                )

                DragAndDropDropZoneContent(
                    target: .tray,
                    isTargeted: airDropViewModel.targetedDropTarget == .tray
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: AirDropDropZoneMetrics.height,
                    maxHeight: AirDropDropZoneMetrics.height
                )
            }
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}
