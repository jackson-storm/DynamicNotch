//
//  вы.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

import Foundation
import SwiftUI

enum LockScreenCustomSoundKind {
    case lock
    case unlock

    var title: String {
        switch self {
        case .lock:
            return String(localized: "Lock sound")
        case .unlock:
            return String(localized: "Unlock sound")
        }
    }

    var description: String {
        switch self {
        case .lock:
            return String(localized: "Played when your Mac locks.")
        case .unlock:
            return String(localized: "Played when your Mac unlocks.")
        }
    }

    var builtInTitle: String {
        switch self {
        case .lock:
            return String(localized: "Built-in lock sound")
        case .unlock:
            return String(localized: "Built-in unlock sound")
        }
    }

    var systemImage: String {
        switch self {
        case .lock:
            return "lock.fill"
        case .unlock:
            return "lock.open.fill"
        }
    }

    var color: Color {
        switch self {
        case .lock:
            return .orange
        case .unlock:
            return .green
        }
    }

    var panelTitle: String {
        switch self {
        case .lock:
            return String(localized: "Choose Lock Sound")
        case .unlock:
            return String(localized: "Choose Unlock Sound")
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .lock:
            return "settings.activities.lockScreen.customSound.lock"
        case .unlock:
            return "settings.activities.lockScreen.customSound.unlock"
        }
    }
}
