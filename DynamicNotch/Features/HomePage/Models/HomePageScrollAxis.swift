//
//  HomePageScrollAxis.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/9/26.
//

import SwiftUI

enum HomePageScrollAxis: String, CaseIterable, Codable, Identifiable {
    case horizontal
    case vertical
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .horizontal: return "settings.homePage.scrollAxis.horizontal"
        case .vertical: return "settings.homePage.scrollAxis.vertical"
        }
    }
}
