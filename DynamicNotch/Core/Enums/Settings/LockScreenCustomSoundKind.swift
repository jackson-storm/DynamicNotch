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

    var titleKey: String {
        switch self {
        case .lock:
            return "Lock sound"
        case .unlock:
            return "Unlock sound"
        }
    }

    var descriptionKey: String {
        switch self {
        case .lock:
            return "Played when your Mac locks."
        case .unlock:
            return "Played when your Mac unlocks."
        }
    }

    var builtInTitleKey: String {
        switch self {
        case .lock:
            return "Built-in lock sound"
        case .unlock:
            return "Built-in unlock sound"
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

    var panelTitleKey: String {
        switch self {
        case .lock:
            return "Choose Lock Sound"
        case .unlock:
            return "Choose Unlock Sound"
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
