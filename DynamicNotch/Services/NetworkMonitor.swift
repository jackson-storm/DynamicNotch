//
//  NetworkMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import Foundation
import Network

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "VPNMonitorQueue")
    
    var onStatusChange: ((Bool) -> Void)?

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.checkVPNStatus(path: path)
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func checkVPNStatus(path: NWPath) {
        let isVPNConnected = path.availableInterfaces.contains { interface in
            let name = interface.name.lowercased()
            return name.starts(with: "utun") ||
                   name.starts(with: "ipsec") ||
                   name.starts(with: "ppp")
        }

        DispatchQueue.main.async {
            self.onStatusChange?(isVPNConnected)
        }
    }
}
