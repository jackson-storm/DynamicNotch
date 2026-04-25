//
//  DragAndDropCombinedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct DragAndDropCombinedNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel

    var body: some View {
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
}
