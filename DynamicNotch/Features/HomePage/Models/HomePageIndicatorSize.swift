//
//  HomePageIndicatorSize.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/8/26.
//

import SwiftUI

enum HomePageIndicatorSize: String, CaseIterable, Codable, Identifiable {
    case small
    case medium
    case large
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .small: return "settings.homePage.indicatorSize.small"
        case .medium: return "settings.homePage.indicatorSize.medium"
        case .large: return "settings.homePage.indicatorSize.large"
        }
    }
    
    var dotSize: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 5
        case .medium: return 6
        case .large: return 7
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 5
        case .large: return 6
        }
    }
}
