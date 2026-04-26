//
//  AirDropDropZoneView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct AirDropNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    
    var body: some View {
        DragAndDropDropZoneView(
            target: .airDrop,
            isTargeted: airDropViewModel.targetedDropTarget == .airDrop
        )
    }
}
