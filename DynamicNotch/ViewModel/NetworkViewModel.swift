//
//  NetworkViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import Foundation
import Combine

final class NetworkViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var event: NetworkEvent? = nil
    
    private let monitor = NetworkMonitor()
    
    init() {
        setupMonitoring()
    }

    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] connected in
            guard let self = self else { return }
            
            if connected && !self.isConnected {
                self.event = .connected
            }
            else if !connected && self.isConnected {
                self.event = .disconnected
            }
            self.isConnected = connected
        }
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
}
