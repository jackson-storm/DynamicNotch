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
    let targetColorStyle: DragAndDropTargetColorStyle

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
            let targets = DragAndDropActivityMode.combined.targets
            let availableWidth = max(proxy.size.width - (horizontalPadding * 2) - (spacing * CGFloat(targets.count - 1)), 0)
            let targetedDropTarget = airDropViewModel.targetedDropTarget
            let expandedPortion: CGFloat = 0.5
            let collapsedPortion: CGFloat = targets.count > 1 ? (1 - expandedPortion) / CGFloat(targets.count - 1) : 1
            let equalPortion = 1 / CGFloat(targets.count)

            VStack {
                Spacer()

                HStack(spacing: spacing) {
                    ForEach(targets, id: \.self) { target in
                        let isTargeted = targetedDropTarget == target
                        let width = availableWidth * (
                            targetedDropTarget == nil ?
                            equalPortion :
                            (isTargeted ? expandedPortion : collapsedPortion)
                        )

                        DragAndDropDropZoneContent(
                            target: target,
                            isTargeted: isTargeted,
                            targetColorStyle: targetColorStyle
                        )
                        .frame(width: width, height: AirDropDropZoneMetrics.height)
                    }
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
                ForEach(DragAndDropActivityMode.combined.targets, id: \.self) { target in
                    DragAndDropDropZoneContent(
                        target: target,
                        isTargeted: airDropViewModel.targetedDropTarget == target,
                        targetColorStyle: targetColorStyle
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: AirDropDropZoneMetrics.height,
                        maxHeight: AirDropDropZoneMetrics.height
                    )
                }
            }
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}
