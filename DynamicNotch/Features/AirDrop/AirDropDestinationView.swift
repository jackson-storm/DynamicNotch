//
//  AirDropDestinationView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AirDropDestinationView: NSViewRepresentable {
    @Binding var isTargeted: Bool
    @Binding var isDropZoneTargeted: Bool
    let onDropPasteboard: (NSPasteboard) -> Bool

    func makeNSView(context: Context) -> AirDropView {
        let view = AirDropView()
        view.onTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isTargeted = isTargeted
            }
        }
        view.onDropZoneTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isDropZoneTargeted = isTargeted
            }
        }
        view.onDropPasteboard = onDropPasteboard
        return view
    }

    func updateNSView(_ nsView: AirDropView, context: Context) {
        nsView.onTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isTargeted = isTargeted
            }
        }
        nsView.onDropZoneTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isDropZoneTargeted = isTargeted
            }
        }
        nsView.onDropPasteboard = onDropPasteboard
    }
}

final class AirDropView: NSView {
    var onTargetedChange: (Bool) -> Void = { _ in }
    var onDropZoneTargetedChange: (Bool) -> Void = { _ in }
    var onDropPasteboard: (NSPasteboard) -> Bool = { _ in false }

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
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp:
            return nil
        default:
            return super.hitTest(point)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.containsAirDropFiles else {
            onTargetedChange(false)
            onDropZoneTargetedChange(false)
            return []
        }

        onTargetedChange(true)
        let isInsideDropZone = isDropPointInsideTargetZone(sender)
        onDropZoneTargetedChange(isInsideDropZone)
        return isInsideDropZone ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.containsAirDropFiles else {
            onTargetedChange(false)
            onDropZoneTargetedChange(false)
            return []
        }

        onTargetedChange(true)
        let isInsideDropZone = isDropPointInsideTargetZone(sender)
        onDropZoneTargetedChange(isInsideDropZone)
        return isInsideDropZone ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
        onDropZoneTargetedChange(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.containsAirDropFiles && isDropPointInsideTargetZone(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard sender.draggingPasteboard.containsAirDropFiles, isDropPointInsideTargetZone(sender) else {
            onDropZoneTargetedChange(false)
            return false
        }

        let result = onDropPasteboard(sender.draggingPasteboard)
        onTargetedChange(false)
        onDropZoneTargetedChange(false)
        return result
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
        onDropZoneTargetedChange(false)
    }

    private func isDropPointInsideTargetZone(_ sender: NSDraggingInfo) -> Bool {
        let location = convert(sender.draggingLocation, from: nil)
        return targetDropZoneRect.contains(location)
    }

    private var targetDropZoneRect: NSRect {
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
