//
//  DragAndDropCombinedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct DragAndDropCombinedNotchView: View {
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var airDropViewModel: AirDropNotchViewModel

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: AirDropDropZoneMetrics.combinedSpacing) {
                ForEach(DragAndDropActivityMode.combined.targets, id: \.self) { target in
                    DragAndDropDropZoneContent(
                        target: target,
                        isTargeted: airDropViewModel.targetedDropTarget == target
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: AirDropDropZoneMetrics.height,
                        maxHeight: AirDropDropZoneMetrics.height
                    )
                }
            }
        }
        .padding(.horizontal, isNotchlessScreen ? 10 : AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, isNotchlessScreen ? 10 : AirDropDropZoneMetrics.verticalPadding)
    }
}
