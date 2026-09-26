import Foundation
import SwiftUI

enum NotchAnimationPreset: String, CaseIterable {
    case balanced

    var title: LocalizedStringKey {
        "settings.general.animation.balanced"
    }

    var symbolName: String {
        "gauge"
    }

    var description: String {
        "Default motion with a balanced spring feel for everyday use."
    }
}
