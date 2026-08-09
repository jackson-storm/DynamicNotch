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
    @Published private(set) var activeTransfer: AirDropTransferInfo?

    private var completionTask: Task<Void, Never>?

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

    func beginTransfer(id: UUID, urls: [URL], initialProgress: Double = 0.0) {
        completionTask?.cancel()
        activeTransfer = AirDropTransferInfo(id: id, urls: urls, status: .transferring, progress: initialProgress)
    }

    func updateTransferProgress(id: UUID, progress: Double) {
        guard var current = activeTransfer, current.id == id else { return }
        current.progress = max(0.0, min(1.0, progress))
        activeTransfer = current
    }

    func cancelTransfer(id: UUID) {
        completionTask?.cancel()
        guard var current = activeTransfer, current.id == id else {
            activeTransfer = nil
            return
        }
        current.status = .failed("Canceled")
        activeTransfer = current
        scheduleClear(id: id, duration: 2_000_000_000)
    }

    func completeTransfer(id: UUID) {
        guard var current = activeTransfer, current.id == id else {
            activeTransfer = AirDropTransferInfo(id: id, urls: [], status: .completed)
            scheduleClear(id: id, duration: 2_500_000_000)
            return
        }

        current.status = .completed
        activeTransfer = current
        scheduleClear(id: id, duration: 2_500_000_000)
    }

    func failTransfer(id: UUID, error: Error) {
        guard var current = activeTransfer, current.id == id else {
            activeTransfer = AirDropTransferInfo(id: id, urls: [], status: .failed(error.localizedDescription))
            scheduleClear(id: id, duration: 3_000_000_000)
            return
        }

        current.status = .failed(error.localizedDescription)
        activeTransfer = current
        scheduleClear(id: id, duration: 3_000_000_000)
    }

    func clearTransfer() {
        completionTask?.cancel()
        activeTransfer = nil
    }

    private func scheduleClear(id: UUID, duration: UInt64) {
        completionTask?.cancel()
        completionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: duration)
            guard !Task.isCancelled else { return }
            if self.activeTransfer?.id == id {
                self.activeTransfer = nil
            }
        }
    }
}
