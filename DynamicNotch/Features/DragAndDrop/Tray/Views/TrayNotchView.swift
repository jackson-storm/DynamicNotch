//
//  TrayNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct TrayNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel

    var body: some View {
        DragAndDropDropZoneView(
            target: .tray,
            isTargeted: airDropViewModel.targetedDropTarget == .tray
        )
    }
}
