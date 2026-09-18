//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectedNotchContent : NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Vpn.vpn.id
    var priority: Int { NotchContentRegistry.Vpn.vpn.priority }
    
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
            width: isVPNDetailVisible ? baseWidth + 155 : baseWidth + 115,
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
            VpnConnectedNotchView(
                vpnViewModel: vpnViewModel,
                settings: settings
            )
        )
    }
}
