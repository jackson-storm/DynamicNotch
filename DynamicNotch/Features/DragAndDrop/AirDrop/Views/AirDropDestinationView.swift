//
//  AirDropDestinationView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DragAndDropDestinationView: NSViewRepresentable {
    @Binding var isTargeted: Bool
    @Binding var targetedDropTarget: DragAndDropTarget?
    let mode: DragAndDropActivityMode
    let onDropPasteboard: (DragAndDropTarget, NSPasteboard) -> Bool

    func makeNSView(context: Context) -> DragAndDropView {
        let view = DragAndDropView()
        view.mode = mode
        view.onTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isTargeted = isTargeted
            }
        }
        view.onTargetedDropTargetChange = { target in
            DispatchQueue.main.async {
                self.targetedDropTarget = target
            }
        }
        view.onDropPasteboard = onDropPasteboard
        return view
    }

    func updateNSView(_ nsView: DragAndDropView, context: Context) {
        nsView.mode = mode
        nsView.onTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isTargeted = isTargeted
            }
        }
        nsView.onTargetedDropTargetChange = { target in
            DispatchQueue.main.async {
                self.targetedDropTarget = target
            }
        }
        nsView.onDropPasteboard = onDropPasteboard
    }
}

final class DragAndDropView: NSView {
    var mode: DragAndDropActivityMode = .airDrop
    var onTargetedChange: (Bool) -> Void = { _ in }
    var onTargetedDropTargetChange: (DragAndDropTarget?) -> Void = { _ in }
    var onDropPasteboard: (DragAndDropTarget, NSPasteboard) -> Bool = { _, _ in false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType(UTType.data.identifier)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        switch NSApp.currentEvent?.type {
        case .leftMouseDown,
             .leftMouseUp,
             .rightMouseDown,
             .rightMouseUp,
             .otherMouseDown,
             .otherMouseUp,
             .scrollWheel,
             .swipe,
             .gesture,
             .magnify,
             .rotate,
             .beginGesture,
             .endGesture,
             .smartMagnify,
             .mouseMoved,
             .mouseEntered,
             .mouseExited,
             .cursorUpdate:
            return nil
        default:
            return super.hitTest(point)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.isFileTrayLocalDrag == false,
              sender.draggingPasteboard.containsAirDropFiles else {
            onTargetedChange(false)
            onTargetedDropTargetChange(nil)
            return []
        }

        onTargetedChange(true)
        let target = dropTarget(for: sender)
        onTargetedDropTargetChange(target)
        return target == nil ? [] : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.isFileTrayLocalDrag == false,
              sender.draggingPasteboard.containsAirDropFiles else {
            onTargetedChange(false)
            onTargetedDropTargetChange(nil)
            return []
        }

        onTargetedChange(true)
        let target = dropTarget(for: sender)
        onTargetedDropTargetChange(target)
        return target == nil ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
        onTargetedDropTargetChange(nil)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.isFileTrayLocalDrag == false &&
        sender.draggingPasteboard.containsAirDropFiles &&
        dropTarget(for: sender) != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard sender.draggingPasteboard.isFileTrayLocalDrag == false,
              sender.draggingPasteboard.containsAirDropFiles,
              let target = dropTarget(for: sender) else {
            onTargetedDropTargetChange(nil)
            return false
        }

        let result = onDropPasteboard(target, sender.draggingPasteboard)
        onTargetedChange(false)
        onTargetedDropTargetChange(nil)
        return result
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
        onTargetedDropTargetChange(nil)
    }

    private func dropTarget(for sender: NSDraggingInfo) -> DragAndDropTarget? {
        let location = convert(sender.draggingLocation, from: nil)
        return DragAndDropTarget.allCases.first { targetDropZoneRect(for: $0).contains(location) }
    }

    private func targetDropZoneRect(for target: DragAndDropTarget) -> NSRect {
        switch mode {
        case .airDrop:
            return target == .airDrop ? outerDropZoneRect : .null
        case .tray:
            return target == .tray ? outerDropZoneRect : .null
        case .combined:
            let spacing = AirDropDropZoneMetrics.combinedSpacing
            let itemWidth = max((outerDropZoneRect.width - spacing) / 2, 0)
            let xOffset: CGFloat = target == .airDrop ? 0 : itemWidth + spacing

            return NSRect(
                x: outerDropZoneRect.minX + xOffset,
                y: outerDropZoneRect.minY,
                width: itemWidth,
                height: outerDropZoneRect.height
            )
        }
    }

    private var outerDropZoneRect: NSRect {
        let width = max(bounds.width - (AirDropDropZoneMetrics.horizontalPadding * 2), 0)
        let height = min(AirDropDropZoneMetrics.height, bounds.height)

        return NSRect(
            x: AirDropDropZoneMetrics.horizontalPadding,
            y: AirDropDropZoneMetrics.verticalPadding,
            width: width,
            height: height
        )
    }
}
