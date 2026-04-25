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
    @Published private(set) var targetedDropTarget: DragAndDropTarget?

    func setDraggingFile(_ isDraggingFile: Bool) {
        guard self.isDraggingFile != isDraggingFile else { return }

        self.isDraggingFile = isDraggingFile
        if !isDraggingFile {
            isDropZoneTargeted = false
            targetedDropTarget = nil
        }
        event = isDraggingFile ? .dragStarted : .dragEnded
    }

    func setDropZoneTargeted(_ isTargeted: Bool) {
        setTargetedDropTarget(isTargeted ? .airDrop : nil)
    }

    func setTargetedDropTarget(_ target: DragAndDropTarget?) {
        guard targetedDropTarget != target else { return }
        targetedDropTarget = target
        isDropZoneTargeted = target != nil
    }

    func handleSuccessfulDrop() {
        isDraggingFile = false
        isDropZoneTargeted = false
        targetedDropTarget = nil
        event = .dropped
    }
}
