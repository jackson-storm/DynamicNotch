//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol {
    let id = "hotspot.active"
    let settingsViewModel: SettingsViewModel
    
    private var appearanceStyle: HotspotAppearanceStyle {
        settingsViewModel.connectivity.hotspotAppearanceStyle
    }
    
    var priority: Int { 70 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isHotspotDefaultStrokeEnabled ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
    }
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = appearanceStyle == .minimal ? 80 : 80
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotActiveNotchView(style: appearanceStyle))
    }
}
