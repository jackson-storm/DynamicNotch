//
//  NetworkViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import Combine
import Foundation

final class VpnViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var event: VpnEvent? = nil
    
    private let monitor = NetworkMonitor()
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
