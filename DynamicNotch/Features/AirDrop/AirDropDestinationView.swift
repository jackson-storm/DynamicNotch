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
    let onDropPasteboard: (NSPasteboard) -> Bool

    func makeNSView(context: Context) -> AirDropView {
        let view = AirDropView()
        view.onTargetedChange = { isTargeted in
            DispatchQueue.main.async {
                self.isTargeted = isTargeted
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
        nsView.onDropPasteboard = onDropPasteboard
    }
}

final class AirDropView: NSView {
    var onTargetedChange: (Bool) -> Void = { _ in }
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
            return []
        }

        onTargetedChange(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.containsAirDropFiles else {
            onTargetedChange(false)
            return []
        }

        onTargetedChange(true)
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.containsAirDropFiles
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let result = onDropPasteboard(sender.draggingPasteboard)
        onTargetedChange(false)
        return result
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
    }
}
