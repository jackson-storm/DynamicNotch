//
//  NotchScreenSelectionPreferences.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import Foundation

struct NotchScreenSelectionPreferences: Equatable {
    let displayLocation: NotchDisplayLocation
    let preferredDisplayUUID: String?
    let allowsAutomaticDisplaySwitching: Bool
}
