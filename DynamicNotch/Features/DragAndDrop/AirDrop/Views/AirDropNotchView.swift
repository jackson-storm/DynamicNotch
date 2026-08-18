//
//  AirDropNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel

    private var isTargeted: Bool {
        airDropViewModel.targetedDropTarget == .airDrop
    }

    var body: some View {
        VStack {
            Spacer()

            AirDropDropZoneContent(isTargeted: isTargeted)
                .frame(maxWidth: .infinity, maxHeight: AirDropDropZoneMetrics.height)
        }
        .padding(.horizontal, AirDropDropZoneMetrics.horizontalPadding)
        .padding(.vertical, AirDropDropZoneMetrics.verticalPadding)
    }
}

struct AirDropDropZoneContent: View {
    let isTargeted: Bool

    private var fillColor: Color {
        Color.blue.opacity(isTargeted ? 0.4 : 0.3)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: AirDropDropZoneMetrics.cornerRadius)
            .fill(fillColor)
            .overlay {
                HStack {
                    VStack(spacing: 4) {
                        DragAndDropTarget.airDrop.icon()
                        DragAndDropTarget.airDrop.titleIcon()
                    }

                    Spacer()
                }
                .padding(.leading)
            }
    }
}
