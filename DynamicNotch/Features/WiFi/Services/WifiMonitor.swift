//
//  WifiMonitor.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Network
import CoreWLAN
import SystemConfiguration

final class WifiMonitor: WifiMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "WifiMonitorQueue")
    private let hotspotBatteryMonitor = HotspotBatteryMonitor.shared
    
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)?
    var onHotspotBatteryChange: ((Int) -> Void)?
    private(set) var currentWiFiName: String?
    private(set) var currentVPNName: String?
    private(set) var isInternetAvailable = true
    private(set) var currentWiFiSignalLevel: Double = 1
    var currentHotspotBatteryLevel: Int? {
        hotspotBatteryMonitor.currentBatteryLevel
    }

    init() {
        hotspotBatteryMonitor.onBatteryLevelChange = { [weak self] level in
            print("[WifiMonitor] Received onBatteryLevelChange: \(level)%")
            self?.onHotspotBatteryChange?(level)
        }
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        print("[WifiMonitor] startMonitoring called")
        hotspotBatteryMonitor.startBrowsing()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateStatus(path: path)
        }
        monitor.start(queue: queue)
    }

    private func updateStatus(path: NWPath) {
        let hasInternetConnection = path.status == .satisfied
        let isWifi = hasInternetConnection && path.usesInterfaceType(.wifi)
        
        let isHotspot = isWifi && path.isExpensive
        print("[WifiMonitor] updateStatus: isWifi=\(isWifi), isExpensive=\(path.isExpensive), isHotspot=\(isHotspot), battery=\(String(describing: hotspotBatteryMonitor.currentBatteryLevel))")
        
        if isHotspot {
            hotspotBatteryMonitor.startBrowsing()
        }
        
        let isVpn = hasInternetConnection && path.availableInterfaces.contains { interface in
            let name = interface.name.lowercased()
            return name.hasPrefix("utun") || name.hasPrefix("ipsec") || name.hasPrefix("ppp")
        }

        let wifiName = resolveWiFiName(isConnected: isWifi && !isHotspot)
        let wifiSignalLevel = resolveWiFiSignalLevel(isConnected: isWifi && !isHotspot)
        let vpnName = resolveVPNName(isConnected: isVpn)

        DispatchQueue.main.async {
            self.currentWiFiName = wifiName
            self.currentWiFiSignalLevel = wifiSignalLevel
            self.currentVPNName = vpnName
            self.isInternetAvailable = hasInternetConnection
            self.onStatusChange?(isWifi && !isHotspot, isHotspot, isVpn)
        }
    }

    func stopMonitoring() {
        hotspotBatteryMonitor.stopBrowsing()
        monitor.pathUpdateHandler = nil
        monitor.cancel()
    }

    private func resolveWiFiSignalLevel(isConnected: Bool) -> Double {
        guard isConnected,
              let interface = CWWiFiClient.shared().interface()
        else {
            return 0
        }

        let rssi = interface.rssiValue()

        guard rssi < 0 else {
            return 1
        }

        return min(max((Double(rssi) + 90) / 60, 0.08), 1)
    }

    private func resolveWiFiName(isConnected: Bool) -> String? {
        guard isConnected else { return nil }

        let name = CWWiFiClient.shared().interface()?.ssid()?.trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.isEmpty == false ? name : nil
    }

    private func resolveVPNName(isConnected: Bool) -> String? {
        guard isConnected else { return nil }
        guard let store = SCDynamicStoreCreate(nil, "DynamicNotch.WifiMonitor" as CFString, nil, nil),
              let preferences = SCPreferencesCreate(nil, "DynamicNotch.WifiMonitor" as CFString, nil),
              let services = SCNetworkServiceCopyAll(preferences) as? [SCNetworkService] else {
            return nil
        }

        let activeServiceIDs = activeVPNServiceIDs(from: store)
        let activeServices = services.filter { service in
            guard let serviceID = SCNetworkServiceGetServiceID(service) as String? else {
                return false
            }

            return activeServiceIDs.contains(serviceID)
        }

        if let displayName = activeServices
            .compactMap(serviceDisplayName(for:))
            .first(where: { !$0.isEmpty }) {
            return displayName
        }

        return nil
    }

    private func activeVPNServiceIDs(from store: SCDynamicStore) -> Set<String> {
        let patterns = [
            "State:/Network/Service/.*/PPP",
            "State:/Network/Service/.*/IPSec",
            "State:/Network/Service/.*/VPN"
        ]

        return patterns.reduce(into: Set<String>()) { result, pattern in
            guard let keys = SCDynamicStoreCopyKeyList(store, pattern as CFString) as? [String] else {
                return
            }

            for key in keys {
                guard let serviceID = extractServiceID(from: key) else {
                    continue
                }

                result.insert(serviceID)
            }
        }
    }

    private func extractServiceID(from key: String) -> String? {
        let components = key.split(separator: "/")
        guard let serviceIndex = components.firstIndex(of: "Service"),
              components.indices.contains(serviceIndex + 1) else {
            return nil
        }

        return String(components[serviceIndex + 1])
    }

    private func serviceDisplayName(for service: SCNetworkService) -> String? {
        let name = (SCNetworkServiceGetName(service) as String?)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.isEmpty == false ? name : nil
    }

    private func isLikelyVPNService(_ service: SCNetworkService) -> Bool {
        guard let interface = SCNetworkServiceGetInterface(service) else {
            return false
        }

        let values = [
            SCNetworkInterfaceGetInterfaceType(interface) as String?,
            SCNetworkInterfaceGetLocalizedDisplayName(interface) as String?
        ]
        .compactMap { $0?.lowercased() }

        return values.contains { value in
            value.contains("vpn") ||
            value.contains("ppp") ||
            value.contains("ipsec") ||
            value.contains("l2tp") ||
            value.contains("utun")
        }
    }
}
