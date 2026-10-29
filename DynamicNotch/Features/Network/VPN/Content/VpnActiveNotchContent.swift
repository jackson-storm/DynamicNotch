//
//  VpnActiveNotchContent.swift
//  DynamicNotch
//

import SwiftUI
internal import AppKit

struct VpnActiveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Vpn.vpn.id
    let vpnViewModel: VpnViewModel
    let notchViewModel: NotchViewModel

    var priority: Int { NotchContentRegistry.Vpn.vpn.priority }
    var isExpandable: Bool { true }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 105, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 105, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 160, height: baseHeight + 65)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 250, height: baseHeight + 65)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.45
    }

    var windowLink: (@MainActor () -> Void)? {
        return {
            Self.openSystemVpnSettings()
        }
    }

    @MainActor
    private static func openSystemVpnSettings() {
        let vpnURLs = [
            "x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension",
            "x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI",
            "x-apple.systempreferences:com.apple.Network-Settings.extension?VPN",
            "x-apple.systempreferences:com.apple.preference.network?VPN",
            "x-apple.systempreferences:com.apple.preference.network"
        ]
        for urlString in vpnURLs {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            VpnActiveNotchView(vpnViewModel: vpnViewModel)
        )
    }

    @MainActor
    func expandedView() -> AnyView {
        AnyView(
            VpnExpandedNotchView(
                notchViewModel: notchViewModel,
                viewModel: vpnViewModel
            )
        )
    }
}
