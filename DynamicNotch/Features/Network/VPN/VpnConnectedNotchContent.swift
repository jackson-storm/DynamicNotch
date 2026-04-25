//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectedNotchContent : NotchContentProtocol {
    let id = NotchContentRegistry.Network.vpn.id
    var priority: Int { NotchContentRegistry.Network.vpn.priority }
    
    let networkViewModel: NetworkViewModel
    let settings: ConnectivitySettingsStore
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: Int
        
        if settings.isVPNDetailVisible {
            width = settings.isVPNTimerVisible ? 210 : 205
        } else {
            width = 170
        }
        
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            VpnConnectedNotchView(
                networkViewModel: networkViewModel,
                settings: settings
            )
        )
    }
}
