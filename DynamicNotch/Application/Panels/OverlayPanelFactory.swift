//
//  OverlayPanelFactory.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/28/26.
//

import SwiftUI

enum OverlayPanelFactory {
    static func collectionBehavior(includesFullscreenAuxiliary: Bool = true) -> NSWindow.CollectionBehavior {
        var behavior: NSWindow.CollectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]

        if includesFullscreenAuxiliary {
            behavior.insert(.fullScreenAuxiliary)
        }

        return behavior
    }

    static func makePanel(frame: NSRect, level: NSWindow.Level, isFloatingPanel: Bool = true) -> OverlayPanelWindow {
        let window = OverlayPanelWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configure(window, level: level, isFloatingPanel: isFloatingPanel)
        return window
    }

    static func configure(_ window: NSPanel, level: NSWindow.Level, isFloatingPanel: Bool = true) {
        window.isReleasedWhenClosed = false
        window.isFloatingPanel = isFloatingPanel
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.hasShadow = false
        window.animationBehavior = .none
        window.level = level
        window.collectionBehavior = collectionBehavior()
        window.acceptsMouseMovedEvents = true
    }
}
