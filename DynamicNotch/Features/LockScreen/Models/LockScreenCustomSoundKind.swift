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
            return "settings.lockScreen.customSound.lock.title"
        case .unlock:
            return "settings.lockScreen.customSound.unlock.title"
        }
    }

    var descriptionKey: String {
        switch self {
        case .lock:
            return "settings.lockScreen.customSound.lock.desc"
        case .unlock:
            return "settings.lockScreen.customSound.unlock.desc"
        }
    }

    var builtInTitleKey: String {
        switch self {
        case .lock:
            return "settings.lockScreen.customSound.lock.builtInTitle"
        case .unlock:
            return "settings.lockScreen.customSound.unlock.builtInTitle"
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
            return "settings.lockScreen.customSound.lock.panelTitle"
        case .unlock:
            return "settings.lockScreen.customSound.unlock.panelTitle"
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
