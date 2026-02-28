//
//  WifiMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)?

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateStatus(path: path)
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(path: NWPath) {
        let isWifi = path.usesInterfaceType(.wifi) && path.status == .satisfied
        
        let isHotspot = isWifi && path.isExpensive
        
        let isVpn = path.availableInterfaces.contains { interface in
            let name = interface.name.lowercased()
            return name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp")
        }

        DispatchQueue.main.async {
            self.onStatusChange?(isWifi && !isHotspot, isHotspot, isVpn)
        }
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
