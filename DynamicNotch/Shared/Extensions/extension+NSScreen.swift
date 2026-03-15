//
//  extension+NSScreen.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/12/26.
//

import SwiftUI

extension NSScreen {
    static var screenWithMouse: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
    }

    static var preferredLockScreen: NSScreen? {
        screens.first(where: \.isBuiltInDisplay) ?? main ?? screenWithMouse ?? screens.first
    }

    static func preferredNotchScreen(for location: NotchDisplayLocation) -> NSScreen? {
        switch location {
        case .builtIn:
            return screens.first(where: \.isBuiltInDisplay) ?? screenWithMouse ?? main ?? screens.first
        case .main:
            return main ?? screenWithMouse ?? screens.first
        }
    }

    static func metrics(for location: NotchDisplayLocation) -> NotchScreenMetrics? {
        guard let screen = preferredNotchScreen(for: location) else {
            return nil
        }

        return (
            width: screen.frame.width,
            topInset: screen.safeAreaInsets.top
        )
    }

    private var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    var isBuiltInDisplay: Bool {
        guard let displayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
}
