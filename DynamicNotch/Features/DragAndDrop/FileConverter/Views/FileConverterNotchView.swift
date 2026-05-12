//
//  FileConverterView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    let targetColorStyle: DragAndDropTargetColorStyle

    var body: some View {
        DragAndDropDropZoneView(
            target: .fileConverter,
            isTargeted: airDropViewModel.targetedDropTarget == .fileConverter,
            targetColorStyle: targetColorStyle
        )
    }
}
