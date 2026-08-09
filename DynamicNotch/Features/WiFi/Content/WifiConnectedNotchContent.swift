//
//  WifiConnectedNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import SwiftUI

struct WifiConnectedNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Wifi.wifi.id
    var priority: Int { NotchContentRegistry.Wifi.wifi.priority }
    
    let wifiViewModel: WifiViewModel
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 50, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            WifiConnectedNotchView(
                wifiViewModel: wifiViewModel
            )
        )
    }
}
