//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine
import SwiftUI

enum NetworkEvent: Equatable {
    case wifiConnected
    case vpnConnected
    case hotspotActive
    case hotspotHide
}

final class NetworkViewModel: ObservableObject {
    @Published var wifiConnected: Bool = false
    @Published var hotspotActive: Bool = false
    @Published var vpnConnected: Bool = false
    @Published var wifiName: String = ""
    @Published var vpnName: String = ""
    @Published var vpnConnectedAt: Date?
    
    @Published var networkEvent: NetworkEvent? = nil
    
    private let monitor: any NetworkMonitoring
    private var isInitialCheck = true
    
    init(monitor: any NetworkMonitoring = NetworkMonitor()) {
        self.monitor = monitor
        setupMonitoring()
    }

    deinit {
        monitor.stopMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] wifi, hotspot, vpn in
            guard let self = self else { return }

            self.wifiName = (wifi && !hotspot) ? (self.monitor.currentWiFiName ?? "") : ""
            self.vpnName = vpn ? (self.monitor.currentVPNName ?? "") : ""

            if vpn {
                if self.vpnConnected == false {
                    self.vpnConnectedAt = .now
                }
            } else {
                self.vpnConnectedAt = nil
            }
            
            if !self.isInitialCheck {
                if wifi && !self.wifiConnected {
                    self.networkEvent = .wifiConnected
                }
                if vpn && !self.vpnConnected {
                    self.networkEvent = .vpnConnected
                }
                if hotspot && !self.hotspotActive {
                    self.networkEvent = .hotspotActive
                }
                if !hotspot && self.hotspotActive {
                    self.networkEvent = .hotspotHide
                }
            } else if hotspot {
                self.networkEvent = .hotspotActive
            }
            
            self.wifiConnected = wifi
            self.hotspotActive = hotspot
            self.vpnConnected = vpn
            
            if self.isInitialCheck { self.isInitialCheck = false }
        }
        monitor.startMonitoring()
    }
}
