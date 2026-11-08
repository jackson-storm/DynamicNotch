//
//  NotchDisplayOption.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import Foundation
import CoreGraphics

struct NotchDisplayOption: Identifiable, Hashable {
    let displayUUID: String
    let displayID: CGDirectDisplayID?
    let name: String
    let isBuiltIn: Bool
    let isMain: Bool
    let isAvailable: Bool
    let frame: CGRect?

    var id: String {
        displayUUID
    }

    var symbolName: String {
        if !isAvailable {
            return "display.trianglebadge.exclamationmark"
        }

        if isBuiltIn {
            return "macbook.gen2"
        }

        if isMain {
            return "desktopcomputer.and.macbook"
        }

        return "display"
    }

    static func unavailable(displayUUID: String, name: String) -> NotchDisplayOption {
        NotchDisplayOption(
            displayUUID: displayUUID,
            displayID: nil,
            name: name,
            isBuiltIn: false,
            isMain: false,
            isAvailable: false,
            frame: nil
        )
    }
}
