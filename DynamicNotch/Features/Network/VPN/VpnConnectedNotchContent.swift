//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectedNotchContent : NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Network.vpn.id
    var priority: Int { NotchContentRegistry.Network.vpn.priority }
    
    let networkViewModel: NetworkViewModel
    let settings: ConnectivitySettingsStore
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (
            top: settings.isVPNDetailVisible ? 20 : baseRadius - 4 ,
            bottom: settings.isVPNDetailVisible ? 38 : baseRadius
        )
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: settings.isVPNDetailVisible ? baseWidth + 145 : baseWidth + 110,
            height: settings.isVPNDetailVisible ? 95 : baseHeight
        )
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: settings.isVPNDetailVisible ? baseWidth + 185 : baseWidth + 110,
            height: settings.isVPNDetailVisible ? 85 : baseHeight
        )
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
