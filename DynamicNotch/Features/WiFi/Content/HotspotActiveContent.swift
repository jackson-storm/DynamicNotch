//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotActiveContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Wifi.hotspot.id
    let settingsViewModel: SettingsViewModel
    var wifiViewModel: WifiViewModel? = nil
    
    var appearanceStyle: HotspotAppearanceStyle { settingsViewModel.connectivity.hotspotAppearanceStyle}
    var priority: Int { NotchContentRegistry.Wifi.hotspot.priority }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isHotspotDefaultStrokeEnabled ?
            .white.opacity(0.2) :
            .green.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraWidth: CGFloat = appearanceStyle == .battery ? 100 : 80
        return .init(width: baseWidth + extraWidth, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            HotspotActiveNotchView(
                style: appearanceStyle,
                wifiViewModel: wifiViewModel,
                batteryLevel: wifiViewModel?.hotspotBatteryLevel
            )
        )
    }
}
