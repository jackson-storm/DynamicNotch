//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Network.hotspot.id
    let settingsViewModel: SettingsViewModel
    
    var appearanceStyle: HotspotAppearanceStyle { settingsViewModel.connectivity.hotspotAppearanceStyle}
    var priority: Int { NotchContentRegistry.Network.hotspot.priority }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isHotspotDefaultStrokeEnabled ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 80, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 60, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotActiveNotchView(style: appearanceStyle))
    }
}
