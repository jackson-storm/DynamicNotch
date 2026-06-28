//
//  OverlayWindowLevel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/28/26.
//

import SwiftUI

enum OverlayWindowLevel {
    static let interactiveNotch = NSWindow.Level.mainMenu + 3
    static let shieldingOverlay = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
    static let lockScreenPanel = shieldingOverlay
    static let lockScreenNotch = NSWindow.Level(rawValue: shieldingOverlay.rawValue + 1)
}
