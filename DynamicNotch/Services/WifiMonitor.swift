//
//  WifiMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Network
import CoreWLAN

class WiFiMonitor {
    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let queue = DispatchQueue(label: "WiFiMonitorQueue")
    
    var onStatusChange: ((Bool, Bool) -> Void)?

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
        let isConnected = path.status == .satisfied && path.usesInterfaceType(.wifi)
        
        var isHotspot = path.isExpensive
        
        if isConnected, let interface = CWWiFiClient.shared().interface() {
            if let name = interface.interfaceName, name.contains("p2p") {
                isHotspot = false
            }
        }

        DispatchQueue.main.async {
            self.onStatusChange?(isConnected, isHotspot)
        }
    }
}
