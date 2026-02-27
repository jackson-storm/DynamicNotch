//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine
import SwiftUI

final class WiFiViewModel: ObservableObject {
    @Published var event: WiFiEvent? = nil
    @Published var isConnected: Bool = false
    @Published var isHotspot: Bool = false
    
    private let monitor = WiFiMonitor()
    private var isInitialCheck = true
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] connected, hotspot in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if !self.isInitialCheck {
                    if connected && !self.isConnected {
                        self.event = .connected
                    }
                    else if !connected && self.isConnected {
                        self.event = .disconnected
                    }
                }
                
                self.isConnected = connected
                self.isHotspot = hotspot
                
                if self.isInitialCheck {
                    self.isInitialCheck = false
                }
            }
        }
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
}
