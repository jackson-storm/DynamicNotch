//
//  AirDropViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI
import Combine

@MainActor
final class AirDropNotchViewModel: ObservableObject {
    @Published private(set) var event: AirDropEvent?
    @Published private(set) var isDraggingFile = false
    @Published private(set) var isDropZoneTargeted = false

    func setDraggingFile(_ isDraggingFile: Bool) {
        guard self.isDraggingFile != isDraggingFile else { return }

        self.isDraggingFile = isDraggingFile
        if !isDraggingFile {
            isDropZoneTargeted = false
        }
        event = isDraggingFile ? .dragStarted : .dragEnded
    }

    func setDropZoneTargeted(_ isTargeted: Bool) {
        guard isDropZoneTargeted != isTargeted else { return }
        isDropZoneTargeted = isTargeted
    }

    func handleSuccessfulDrop() {
        isDraggingFile = false
        isDropZoneTargeted = false
        event = .dropped
    }
}
