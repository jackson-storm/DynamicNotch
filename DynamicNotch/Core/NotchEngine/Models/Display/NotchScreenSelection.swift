//
//  NotchScreenSelection.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

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

struct NotchScreenSelectionCandidate: Equatable {
    let displayID: CGDirectDisplayID
    let displayUUID: String
    let isBuiltIn: Bool
}
