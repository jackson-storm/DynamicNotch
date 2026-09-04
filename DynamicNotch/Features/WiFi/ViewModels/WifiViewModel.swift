//
//  WifiViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import Foundation
import Combine
import SwiftUI

enum WifiEvent: Equatable {
    case wifiConnected
    case hotspotActive
    case hotspotHide
    case noInternetConnection
}

@MainActor
final class WifiViewModel: ObservableObject {
    @Published var wifiConnected: Bool = false
    @Published var hotspotActive: Bool = false
    @Published var isInternetAvailable: Bool = true
    @Published var wifiName: String = ""
    @Published var wifiSignalLevel: Double = 1
    @Published var hotspotBatteryLevel: Int? = nil
    @Published var wifiEvent: WifiEvent? = nil
    
    private let monitor: any WifiMonitoring
    private let settings: ConnectivitySettingsStore
    private var isInitialCheck = true
    
    init(
        monitor: any WifiMonitoring,
        settings: ConnectivitySettingsStore
    ) {
        self.monitor = monitor
        self.settings = settings
        setupMonitoring()
    }

    convenience init(settings: ConnectivitySettingsStore) {
        self.init(
            monitor: WifiMonitor(),
            settings: settings
        )
    }

    convenience init() {
        self.init(
            monitor: WifiMonitor(),
            settings: ConnectivitySettingsStore(defaults: .standard)
        )
    }

    private func setupMonitoring() {
        monitor.onStatusChange = { [weak self] wifi, hotspot, _ in
            guard let self = self else { return }

            let nextWiFiName = (wifi && !hotspot) ? (self.monitor.currentWiFiName ?? "") : ""
            let nextInternetAvailable = self.monitor.isInternetAvailable

            self.wifiName = nextWiFiName
            
            if !self.isInitialCheck {
                var pendingEvents: [WifiEvent] = []
                
                if self.shouldEmitConnectionNotification(
                    isConnected: wifi && !hotspot,
                    wasConnected: self.wifiConnected
                ) {
                    pendingEvents.append(.wifiConnected)
                }
                if hotspot && !self.hotspotActive {
                    pendingEvents.append(.hotspotActive)
                }
                if !hotspot && self.hotspotActive {
                    pendingEvents.insert(.hotspotHide, at: 0)
                }
                if !nextInternetAvailable && self.isInternetAvailable {
                    pendingEvents.append(.noInternetConnection)
                }
                
                if let first = pendingEvents.first {
                    self.wifiEvent = first
                    for (index, event) in pendingEvents.dropFirst().enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 * Double(index + 1)) {
                            self.wifiEvent = event
                        }
                    }
                }
            } else if hotspot {
                self.wifiEvent = .hotspotActive
            }
            
            self.wifiConnected = wifi
            self.hotspotActive = hotspot
            self.isInternetAvailable = nextInternetAvailable
            print("[WifiViewModel] onStatusChange: wifi=\(wifi), hotspot=\(hotspot), isInitial=\(self.isInitialCheck)")
            if hotspot {
                self.hotspotBatteryLevel = self.monitor.currentHotspotBatteryLevel ?? HotspotBatteryMonitor.shared.currentBatteryLevel
                print("[WifiViewModel] Hotspot active, set hotspotBatteryLevel = \(String(describing: self.hotspotBatteryLevel))")
            } else {
                self.hotspotBatteryLevel = nil
            }
            
            if self.isInitialCheck { self.isInitialCheck = false }
        }
        monitor.onHotspotBatteryChange = { [weak self] level in
            guard let self = self, self.hotspotActive else { return }
            print("[WifiViewModel] onHotspotBatteryChange received: \(level)%")
            self.hotspotBatteryLevel = level
        }
        monitor.startMonitoring()
    }

    private func shouldEmitConnectionNotification(
        isConnected: Bool,
        wasConnected: Bool
    ) -> Bool {
        isConnected && !wasConnected
    }
}

extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
