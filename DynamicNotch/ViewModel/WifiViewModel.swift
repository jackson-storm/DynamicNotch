//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine

final class WiFiViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var event: WiFiEvent? = nil
    
    private let monitor = WiFiMonitor()
    private var isInitialCheck = true
    
    init() {
        setupMonitoring()
    }

    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] connected in
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
