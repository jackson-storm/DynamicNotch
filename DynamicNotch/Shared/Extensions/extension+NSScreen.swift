//
//  extension+NSScreen.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/12/26.
//

import SwiftUI

extension NSScreen {
    static func preferredNotchScreen(for location: NotchDisplayLocation) -> NSScreen? {
        switch location {
        case .builtIn:
            return screens.first(where: \.isBuiltInDisplay) ?? screens.first ?? main
        case .main:
            return screens.first ?? main
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
