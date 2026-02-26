//
//  WifiMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Network

class WiFiMonitor {
    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let queue = DispatchQueue(label: "WiFiMonitorQueue")
    
    var onStatusChange: ((Bool) -> Void)?

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.checkWiFiStatus(path: path)
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func checkWiFiStatus(path: NWPath) {
        let isWiFiConnected = path.status == .satisfied
        
        DispatchQueue.main.async {
            self.onStatusChange?(isWiFiConnected)
        }
    }
}
