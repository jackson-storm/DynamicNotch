//
//  HudLayoutType.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/8/26.
//

import SwiftUI

enum HudLayoutType: String, CaseIterable {
    case compact
    case expanded
    
    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "settings.general.hud.layoutType.compact"
        case .expanded:
            return "settings.general.hud.layoutType.expanded"
        }
    }
}
