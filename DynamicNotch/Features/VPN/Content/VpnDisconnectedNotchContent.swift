//
//  VpnDisconnectedNotchContent.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/4/26.
//

import SwiftUI

struct VpnDisconnectedNotchContent : NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Vpn.disconnected.id
    var priority: Int { NotchContentRegistry.Vpn.disconnected.priority }
    
    let vpnViewModel: VpnViewModel
    let settings: ConnectivitySettingsStore
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (
            top: settings.isVPNDetailVisible ? 20 : baseRadius - 4 ,
            bottom: settings.isVPNDetailVisible ? 38 : baseRadius
        )
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: settings.isVPNDetailVisible ? baseWidth + 155 : baseWidth + 110,
            height: settings.isVPNDetailVisible ? 95 : baseHeight
        )
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: settings.isVPNDetailVisible ? baseWidth + 200 : baseWidth + 110,
            height: settings.isVPNDetailVisible ? 85 : baseHeight
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            VpnDisconnectedNotchView(
                vpnViewModel: vpnViewModel,
                settings: settings
            )
        )
    }
}
