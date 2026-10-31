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
            HStack(spacing: 12) {
                ForEach(DragAndDropActivityMode.combined.targets, id: \.self) { target in
                    DragAndDropDropZoneContent(
                        target: target,
                        isTargeted: airDropViewModel.targetedDropTarget == target
                    )
                    .frame(maxWidth: .infinity, minHeight: 90, maxHeight: 90)
                }
            }
        }
        .padding(.top, isNotchlessScreen ? 30 : 35)
        .padding(.horizontal, isNotchlessScreen ? 10 : 35)
    }
}

private struct DragAndDropDropZoneContent: View {
    let target: DragAndDropTarget
    let isTargeted: Bool

    var body: some View {
        switch target {
        case .airDrop:
            AirDropDropZoneContent(isTargeted: isTargeted)
        case .tray:
            TrayDropZoneContent(isTargeted: isTargeted)
        }
    }
}
