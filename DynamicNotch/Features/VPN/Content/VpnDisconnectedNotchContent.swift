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
    private let isVPNDetailVisible: Bool

    @MainActor
    init(
        vpnViewModel: VpnViewModel,
        settings: ConnectivitySettingsStore
    ) {
        self.vpnViewModel = vpnViewModel
        self.settings = settings
        self.isVPNDetailVisible = settings.isVPNDetailVisible
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (
            top: isVPNDetailVisible ? 20 : baseRadius - 4 ,
            bottom: isVPNDetailVisible ? 38 : baseRadius
        )
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: isVPNDetailVisible ? baseWidth + 155 : baseWidth + 135,
            height: isVPNDetailVisible ? 95 : baseHeight
        )
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(
            width: isVPNDetailVisible ? baseWidth + 220 : baseWidth + 60,
            height: isVPNDetailVisible ? 85 : baseHeight
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
