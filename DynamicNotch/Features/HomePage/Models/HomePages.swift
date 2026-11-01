//
//  HomePages.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 9/27/26.
//

import SwiftUI

enum HomePages: String, CaseIterable, Hashable, Codable, Identifiable {
    case camera
    case localTimer
    case vpn
    case screenshots
    case calculator
    case sound
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: return "settings.homePage.pages.camera.title"
        case .localTimer: return "settings.homePage.pages.timer.title"
        case .vpn: return "settings.homePage.pages.vpn.title"
        case .screenshots: return "settings.homePage.pages.screenshots.title"
        case .calculator: return "settings.homePage.pages.calculator.title"
        case .sound: return "settings.homePage.pages.sound.title"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "settings.homePage.pages.camera.subtitle"
        case .localTimer: return "settings.homePage.pages.timer.subtitle"
        case .vpn: return "settings.homePage.pages.vpn.subtitle"
        case .screenshots: return "settings.homePage.pages.screenshots.subtitle"
        case .calculator: return "settings.homePage.pages.calculator.subtitle"
        case .sound: return "settings.homePage.pages.sound.subtitle"
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .localTimer: return "timer"
        case .vpn: return "network.badge.shield.half.filled"
        case .screenshots: return "camera.viewfinder"
        case .calculator: return "plus.forwardslash.minus"
        case .sound: return "speaker.wave.2.fill"
        }
    }
    
    var tint: Color {
        switch self {
        case .camera: return .gray
        case .localTimer: return .orange
        case .vpn: return .blue
        case .screenshots: return .blue
        case .calculator: return .orange
        case .sound: return .white
        }
    }
    
    var iconTint: Color {
        switch self {
        case .camera: return .black
        case .localTimer: return .white
        case .vpn: return .white
        case .screenshots: return .white
        case .calculator: return .white
        case .sound: return .black
        }
    }
}
