//
//  VpnViewModel.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/24/26.
//

import Foundation
import Combine
import SwiftUI

enum VpnEvent: Equatable {
    case vpnConnected
}

@MainActor
final class VpnViewModel: ObservableObject {
    @Published var vpnConnected: Bool = false
    @Published var vpnName: String = ""
    @Published var vpnConnectedAt: Date?
    @Published var vpnBundleID: String? = nil
    @Published var vpnEvent: VpnEvent? = nil
    
    private let monitor: any WifiMonitoring
    private let settings: ConnectivitySettingsStore
    private var isInitialCheck = true
    
    init(
        monitor: any WifiMonitoring,
        settings: ConnectivitySettingsStore
    ) {
        self.monitor = monitor
        self.settings = settings
        setupMonitoring()
    }

    convenience init(settings: ConnectivitySettingsStore) {
        self.init(
            monitor: WifiMonitor(),
            settings: settings
        )
    }

    convenience init() {
        self.init(
            monitor: WifiMonitor(),
            settings: ConnectivitySettingsStore(defaults: .standard)
        )
    }

    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] _, _, vpn in
            guard let self = self else { return }

            let nextVPNName = vpn ? (self.monitor.currentVPNName ?? "") : ""

            self.vpnName = nextVPNName

            if vpn {
                if self.vpnConnected == false {
                    self.vpnConnectedAt = .now
                    Task.detached(priority: .userInitiated) {
                        let activeVPN = VPNStatusFetcher.fetchVPNs().first(where: { $0.isConnected })
                        let actualTime = activeVPN.flatMap { VPNStatusFetcher.fetchVPNConnectedAt(uuid: $0.id) }
                        let bundleID = activeVPN?.bundleID
                        let finalTime = actualTime
                        
                        await MainActor.run { [weak self] in
                            guard let self = self, self.vpnConnected else { return }
                            if let finalTime {
                                self.vpnConnectedAt = finalTime
                            }
                            self.vpnBundleID = bundleID
                        }
                    }
                }
            } else {
                self.vpnConnectedAt = nil
                self.vpnBundleID = nil
            }
            
            if !self.isInitialCheck {
                if vpn && !self.vpnConnected {
                    self.vpnEvent = .vpnConnected
                }
            }
            
            self.vpnConnected = vpn
            
            if self.isInitialCheck { self.isInitialCheck = false }
        }
        monitor.startMonitoring()
    }
}
