//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine
import SwiftUI

final class NetworkViewModel: ObservableObject {
    @Published var wifiConnected: Bool = false
    @Published var hotspotActive: Bool = false
    @Published var vpnConnected: Bool = false
    
    @Published var wifiEvent: WiFiEvent? = nil
    @Published var hotspotEvent: HotspotEvent? = nil
    @Published var vpnEvent: VpnEvent? = nil
    
    private let monitor = NetworkMonitor()
    private var isInitialCheck = true
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] wifi, hotspot, vpn in
            guard let self = self else { return }
            
            if !self.isInitialCheck && wifi != self.wifiConnected {
                self.wifiEvent = wifi ? .connected : .disconnected
            }
            
            if !self.isInitialCheck && hotspot != self.hotspotActive {
                self.hotspotEvent = hotspot ? .active : .disconnected
            } else if self.isInitialCheck && hotspot {
                self.hotspotEvent = .active
            }
            
            if !self.isInitialCheck && vpn != self.vpnConnected {
                self.vpnEvent = vpn ? .connected : .disconnected
            }
            
            self.wifiConnected = wifi
            self.hotspotActive = hotspot
            self.vpnConnected = vpn
            
            if self.isInitialCheck { self.isInitialCheck = false }
        }
        monitor.startMonitoring()
    }
}
