//
//  extension+NSScreen.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/12/26.
//

import SwiftUI

struct NotchScreenSelectionPreferences: Equatable {
    let displayLocation: NotchDisplayLocation
    let preferredDisplayUUID: String?
    let allowsAutomaticDisplaySwitching: Bool
}

struct NotchDisplayOption: Identifiable, Hashable {
    let displayUUID: String
    let displayID: CGDirectDisplayID?
    let name: String
    let isBuiltIn: Bool
    let isMain: Bool
    let isAvailable: Bool
    fileprivate let frame: CGRect?

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

struct NotchScreenSelectionCandidate: Equatable {
    let displayID: CGDirectDisplayID
    let displayUUID: String
    let isBuiltIn: Bool
}

enum NotchScreenSelection {
    static func preferredDisplayID(for preferences: NotchScreenSelectionPreferences, candidates: [NotchScreenSelectionCandidate], primaryDisplayID: CGDirectDisplayID?) -> CGDirectDisplayID? {
        switch preferences.displayLocation {
        case .builtIn:
            return candidates.first(where: \.isBuiltIn)?.displayID

        case .main:
            if let primaryDisplayID, candidates.contains(where: { $0.displayID == primaryDisplayID }) {
                return primaryDisplayID
            }

            return candidates.first?.displayID

        case .specific:
            if let preferredDisplayUUID = preferences.preferredDisplayUUID?.uppercased(),
               let selectedDisplay = candidates.first(where: { $0.displayUUID == preferredDisplayUUID }) {
                return selectedDisplay.displayID
            }

            guard preferences.allowsAutomaticDisplaySwitching else {
                return nil
            }

            if let primaryDisplayID, candidates.contains(where: { $0.displayID == primaryDisplayID }) {
                return primaryDisplayID
            }

            return candidates.first?.displayID
        }
    }
}

extension NSScreen {
    static var screenWithMouse: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
    }

    static var preferredLockScreen: NSScreen? {
        screens.first(where: \.isBuiltInDisplay) ?? main ?? screenWithMouse ?? screens.first
    }

    static func availableNotchDisplays(primaryDisplayID: CGDirectDisplayID? = CGMainDisplayID()) -> [NotchDisplayOption] {
        screens
            .compactMap { screen in
                guard let displayID = screen.displayID,
                      let displayUUID = screen.displayUUIDString else {
                    return nil
                }

                return NotchDisplayOption(
                    displayUUID: displayUUID,
                    displayID: displayID,
                    name: screen.localizedName,
                    isBuiltIn: screen.isBuiltInDisplay,
                    isMain: displayID == primaryDisplayID,
                    isAvailable: true,
                    frame: screen.frame
                )
            }
            .sorted(by: sortDisplayOptions)
    }

    static func preferredNotchDisplay(
        for preferences: NotchScreenSelectionPreferences
    ) -> NotchDisplayOption? {
        let availableDisplays = availableNotchDisplays()
        let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: preferences,
            candidates: notchScreenSelectionCandidates,
            primaryDisplayID: CGMainDisplayID()
        )

        if let selectedDisplayID,
           let selectedDisplay = availableDisplays.first(where: { $0.displayID == selectedDisplayID }) {
            return selectedDisplay
        }

        switch preferences.displayLocation {
        case .builtIn, .specific:
            return nil

        case .main:
            return availableDisplays.first
        }
    }

    static func preferredNotchScreen(for preferences: NotchScreenSelectionPreferences) -> NSScreen? {
        guard let selectedDisplayID = NotchScreenSelection.preferredDisplayID(
            for: preferences,
            candidates: notchScreenSelectionCandidates,
            primaryDisplayID: CGMainDisplayID()
        ) else {
            if preferences.displayLocation == .main {
                return screens.first
            }

            return nil
        }

        return screen(matchingDisplayID: selectedDisplayID)
    }

    static func preferredNotchScreen(for settings: any NotchSettingsProviding) -> NSScreen? {
        preferredNotchScreen(for: settings.screenSelectionPreferences)
    }

    static func preferredNotchScreen(for location: NotchDisplayLocation) -> NSScreen? {
        preferredNotchScreen(
            for: NotchScreenSelectionPreferences(
                displayLocation: location,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            )
        )
    }

    static func metrics(for preferences: NotchScreenSelectionPreferences) -> NotchScreenMetrics? {
        guard let screen = preferredNotchScreen(for: preferences) else {
            return nil
        }

        return (
            width: screen.frame.width,
            topInset: screen.safeAreaInsets.top
        )
    }

    static func metrics(for settings: any NotchSettingsProviding) -> NotchScreenMetrics? {
        metrics(for: settings.screenSelectionPreferences)
    }

    static func metrics(for location: NotchDisplayLocation) -> NotchScreenMetrics? {
        metrics(
            for: NotchScreenSelectionPreferences(
                displayLocation: location,
                preferredDisplayUUID: nil,
                allowsAutomaticDisplaySwitching: false
            )
        )
    }

    private static var notchScreenSelectionCandidates: [NotchScreenSelectionCandidate] {
        screens.compactMap { screen in
            guard let displayID = screen.displayID,
                  let displayUUID = screen.displayUUIDString else {
                return nil
            }

            return NotchScreenSelectionCandidate(
                displayID: displayID,
                displayUUID: displayUUID,
                isBuiltIn: screen.isBuiltInDisplay
            )
        }
    }

    private static func screen(matchingDisplayID displayID: CGDirectDisplayID) -> NSScreen? {
        screens.first { $0.displayID == displayID }
    }

    nonisolated private static func sortDisplayOptions(lhs: NotchDisplayOption, rhs: NotchDisplayOption) -> Bool {
        if lhs.isMain != rhs.isMain {
            return lhs.isMain && !rhs.isMain
        }

        if lhs.isBuiltIn != rhs.isBuiltIn {
            return lhs.isBuiltIn && !rhs.isBuiltIn
        }

        let lhsFrame = lhs.frame ?? .zero
        let rhsFrame = rhs.frame ?? .zero

        if lhsFrame.minX != rhsFrame.minX {
            return lhsFrame.minX < rhsFrame.minX
        }

        if lhsFrame.minY != rhsFrame.minY {
            return lhsFrame.minY < rhsFrame.minY
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    var displayUUIDString: String? {
        guard let displayID,
              let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }

        return (CFUUIDCreateString(nil, uuid) as String).uppercased()
    }

    var isBuiltInDisplay: Bool {
        guard let displayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
}
