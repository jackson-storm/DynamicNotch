//
//  OverlayWindowLayout.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/28/26.
//

import SwiftUI

enum OverlayWindowLayout {
    static let appCanvasSize = CGSize(width: 1000, height: 1000)

    static func lockScreenCanvasFrame(on screen: NSScreen) -> NSRect {
        screen.frame
    }

    static func topAnchoredFrame(on screen: NSScreen, size: CGSize, yOffset: CGFloat = 1) -> NSRect {
        let x = floor(screen.frame.midX - size.width / 2)
        let y = screen.frame.maxY - size.height + yOffset

        return NSRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
