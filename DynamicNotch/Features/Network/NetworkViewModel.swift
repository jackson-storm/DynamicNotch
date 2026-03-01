//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

//
//  NetworkViewModel.swift
//  DynamicNotch
//

import Foundation
import Combine
import SwiftUI

final class NetworkViewModel: ObservableObject {
    @Published var wifiConnected: Bool = false
    @Published var hotspotActive: Bool = false
    @Published var vpnConnected: Bool = false
    
    @Published var networkEvent: NetworkEvent? = nil
    
    private let monitor = NetworkMonitor()
    private var isInitialCheck = true
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] wifi, hotspot, vpn in
            guard let self = self else { return }
            
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
