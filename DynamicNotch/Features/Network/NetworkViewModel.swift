//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine
import SwiftUI

enum NetworkEvent: Equatable {
    case wifiConnected
    case vpnConnected
    case hotspotActive
    case hotspotHide
}

@MainActor
final class NetworkViewModel: ObservableObject {
    @Published var wifiConnected: Bool = false
    @Published var hotspotActive: Bool = false
    @Published var vpnConnected: Bool = false
    @Published var wifiName: String = ""
    @Published var vpnName: String = ""
    @Published var vpnConnectedAt: Date?
    
    @Published var networkEvent: NetworkEvent? = nil
    
    private let monitor: any NetworkMonitoring
    private let settings: ConnectivitySettingsStore
    private var isInitialCheck = true
    private var lastConnectedWiFiIdentity: String?
    private var lastConnectedVPNIdentity: String?
    
    init(
        monitor: any NetworkMonitoring,
        settings: ConnectivitySettingsStore
    ) {
        self.monitor = monitor
        self.settings = settings
        setupMonitoring()
    }

    convenience init(settings: ConnectivitySettingsStore) {
        self.init(
            monitor: NetworkMonitor(),
            settings: settings
        )
    }

    convenience init() {
        self.init(
            monitor: NetworkMonitor(),
            settings: ConnectivitySettingsStore(defaults: .standard)
        )
    }

    deinit {
        monitor.stopMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] wifi, hotspot, vpn in
            guard let self = self else { return }

            let nextWiFiName = (wifi && !hotspot) ? (self.monitor.currentWiFiName ?? "") : ""
            let nextVPNName = vpn ? (self.monitor.currentVPNName ?? "") : ""
            let nextWiFiIdentity = wifi && !hotspot ? self.resolvedIdentity(for: nextWiFiName, fallback: "Wi-Fi") : nil
            let nextVPNIdentity = vpn ? self.resolvedIdentity(for: nextVPNName, fallback: "VPN") : nil

            self.wifiName = nextWiFiName
            self.vpnName = nextVPNName

            if vpn {
                if self.vpnConnected == false {
                    self.vpnConnectedAt = .now
                }
            } else {
                self.vpnConnectedAt = nil
            }
            
            if !self.isInitialCheck {
                if self.shouldEmitConnectionNotification(
                    isConnected: wifi && !hotspot,
                    wasConnected: self.wifiConnected,
                    currentIdentity: nextWiFiIdentity,
                    previousIdentity: self.lastConnectedWiFiIdentity
                ) {
                    self.networkEvent = .wifiConnected
                }
                if self.shouldEmitConnectionNotification(
                    isConnected: vpn,
                    wasConnected: self.vpnConnected,
                    currentIdentity: nextVPNIdentity,
                    previousIdentity: self.lastConnectedVPNIdentity
                ) {
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

            if let nextWiFiIdentity {
                self.lastConnectedWiFiIdentity = nextWiFiIdentity
            }

            if let nextVPNIdentity {
                self.lastConnectedVPNIdentity = nextVPNIdentity
            }
            
            if self.isInitialCheck { self.isInitialCheck = false }
        }
        monitor.startMonitoring()
    }

    private func shouldEmitConnectionNotification(
        isConnected: Bool,
        wasConnected: Bool,
        currentIdentity: String?,
        previousIdentity: String?
    ) -> Bool {
        guard isConnected else { return false }

        if settings.isOnlyNotifyOnNetworkChangeEnabled {
            return currentIdentity != previousIdentity
        }

        return !wasConnected
    }

    private func resolvedIdentity(for name: String, fallback: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? fallback : trimmedName
    }
}
