//
//  AirDropNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    private var isTargeted: Bool {
        airDropViewModel.targetedDropTarget == .airDrop
    }
    
    var body: some View {
        VStack {
            AirDropDropZoneContent(isTargeted: isTargeted)
                .frame(maxWidth: .infinity, maxHeight: 90)
        }
        .padding(.top, isNotchlessScreen ? 30 : 35)
        .padding(.horizontal, isNotchlessScreen ? 10 : 35)
    }
}

struct AirDropDropZoneContent: View {
    let isTargeted: Bool
    
    private var fillColor: Color {
        Color.blue.opacity(isTargeted ? 0.4 : 0.3)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 22)
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
