//
//  VpnViewModel.swift
//  DynamicNotch
//
//  Created by Antigravity on 6/24/26.
//

import Foundation
import Combine
import SwiftUI

enum VpnEvent: Equatable {
    case vpnConnected
    case vpnDisconnected
}

@MainActor
final class VpnViewModel: ObservableObject {
    // Status & Event State
    @Published var vpnConnected: Bool = false
    @Published var vpnName: String = ""
    @Published var vpnConnectedAt: Date?
    @Published var vpnBundleID: String? = nil
    @Published var vpnEvent: VpnEvent? = nil
    @Published var lastVpnName: String = ""
    @Published var lastVpnBundleID: String? = nil
    
    // Configurations & Details
    @Published var vpns: [VPNConfiguration] = []
    @Published var isLoading: Bool = false
    @Published var connectionError: String? = nil
    @Published var currentIP: String? = nil
    @Published var currentCountryCode: String? = nil
    @Published var countryFlag: String? = nil
    @Published var isSystemSettingsVpnOpen: Bool = false
    
    var connectedAt: Date? {
        vpnConnectedAt
    }
    
    private let monitor: any WifiMonitoring
    private let settings: ConnectivitySettingsStore
    private let systemSettingsMonitor: SystemSettingsVpnMonitor
    private var isInitialCheck = true
    private var connectedVPNID: String? = nil
    private var isFetchingLocation: Bool = false
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        monitor: any WifiMonitoring,
        settings: ConnectivitySettingsStore,
        systemSettingsMonitor: SystemSettingsVpnMonitor? = nil
    ) {
        self.monitor = monitor
        self.settings = settings
        self.systemSettingsMonitor = systemSettingsMonitor ?? SystemSettingsVpnMonitor()
        // Seed connection date from system immediately if active
        if let sysDate = VPNStatusFetcher.fetchActiveVPNConnectedAt() {
            self.vpnConnectedAt = sysDate
        }
        setupMonitoring()
        setupSystemSettingsMonitoring()
    }

    private func setupSystemSettingsMonitoring() {
        systemSettingsMonitor.$isVpnTabOpen
            .sink { [weak self] isOpen in
                self?.isSystemSettingsVpnOpen = isOpen
            }
            .store(in: &cancellables)
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
        monitor.onStatusChange = { [weak self] _, _, vpn in
            guard let self = self else { return }

            let nextVPNName = vpn ? (self.monitor.currentVPNName ?? "") : ""

            if vpn {
                self.vpnName = nextVPNName
                self.lastVpnName = nextVPNName
                if self.vpnConnected == false {
                    // Try to get real connection date from macOS system configuration immediately
                    if let sysDate = VPNStatusFetcher.fetchActiveVPNConnectedAt() {
                        self.vpnConnectedAt = sysDate
                    } else if self.vpnConnectedAt == nil {
                        self.vpnConnectedAt = .now
                    }
                    self.refresh()
                }
            } else {
                self.vpnName = ""
                self.vpnConnectedAt = nil
                self.vpnBundleID = nil
                self.connectedVPNID = nil
                self.currentIP = nil
                self.currentCountryCode = nil
                self.countryFlag = nil
            }
            
            if self.isInitialCheck {
                self.isInitialCheck = false
                if vpn {
                    self.vpnEvent = .vpnConnected
                }
            } else {
                if vpn && !self.vpnConnected {
                    self.vpnEvent = .vpnConnected
                } else if !vpn && self.vpnConnected {
                    self.vpnEvent = .vpnDisconnected
                }
            }
            
            self.vpnConnected = vpn
        }
        monitor.startMonitoring()
        
        // Initial fetch of configurations and status
        refresh()
    }
    
    func startMonitoring() {
        refresh()
        guard refreshTimer == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.refresh()
            }
        }
    }
    
    func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func refresh() {
        isLoading = true
        let isCurrentlyConnected = self.vpnConnected
        let currentConnectedDate = self.vpnConnectedAt
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            var list = VPNStatusFetcher.fetchVPNs()
            
            var connDate: Date? = nil
            var activeConnectedUuid: String? = nil
            var serverAddr: String? = nil
            var bundleID: String? = nil
            
            if let activeVpn = list.first(where: { $0.isConnected }) {
                activeConnectedUuid = activeVpn.id
                bundleID = activeVpn.bundleID
                connDate = VPNStatusFetcher.fetchVPNConnectedAt(uuid: activeVpn.id)
                serverAddr = VPNStatusFetcher.fetchVPNServerAddress(uuid: activeVpn.id)
            } else if let activeTuple = VPNStatusFetcher.fetchActiveVPNTuple() {
                activeConnectedUuid = activeTuple.uuid
                connDate = activeTuple.connectedAt
                serverAddr = activeTuple.serverAddress
            }
            
            if connDate == nil {
                connDate = VPNStatusFetcher.fetchActiveVPNConnectedAt()
            }
            
            if let activeId = activeConnectedUuid, let serverAddr {
                list = list.map { item in
                    if item.id == activeId {
                        var updated = item
                        updated.serverAddress = serverAddr
                        return updated
                    }
                    return item
                }
            }
            
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "debug.vpn.mockThreeDigitTimer") && list.isEmpty && !isCurrentlyConnected {
                list = [
                    VPNConfiguration(
                        id: "debug.mock.wireguard",
                        name: "WireGuard Tunnel",
                        isConnected: true,
                        type: "WireGuard",
                        bundleID: nil,
                        serverAddress: "185.220.101.5"
                    )
                ]
                if connDate == nil {
                    connDate = currentConnectedDate ?? Date().addingTimeInterval(-6120)
                }
                if activeConnectedUuid == nil {
                    activeConnectedUuid = "debug.mock.wireguard"
                    serverAddr = "185.220.101.5"
                }
            }
            #endif
            
            let finalVPNList = list
            let finalConnDate = connDate
            let finalActiveUuid = activeConnectedUuid
            let finalServerAddr = serverAddr
            let finalBundleID = bundleID
            
            await MainActor.run {
                if self.vpns != finalVPNList {
                    self.vpns = finalVPNList
                }
                self.isLoading = false
                
                if finalActiveUuid != nil || self.vpnConnected {
                    if let finalConnDate {
                        if let current = self.vpnConnectedAt {
                            // Don't reassign if it's the same session (preventing view redraw/timer reset flicker)
                            if abs(current.timeIntervalSince(finalConnDate)) > 2.0 {
                                self.vpnConnectedAt = finalConnDate
                            }
                        } else {
                            self.vpnConnectedAt = finalConnDate
                        }
                    } else if self.vpnConnectedAt == nil {
                        self.vpnConnectedAt = .now
                    }
                } else {
                    self.vpnConnectedAt = nil
                }
                
                if let finalBundleID {
                    if self.vpnBundleID != finalBundleID {
                        self.vpnBundleID = finalBundleID
                    }
                    if self.lastVpnBundleID != finalBundleID {
                        self.lastVpnBundleID = finalBundleID
                    }
                }
                
                if let uuid = finalActiveUuid {
                    if self.connectedVPNID != uuid {
                        self.connectedVPNID = uuid
                        if let finalServerAddr {
                            self.currentIP = finalServerAddr
                        }
                        self.fetchLocation()
                    } else if self.currentIP == nil, let finalServerAddr {
                        self.currentIP = finalServerAddr
                    }
                } else {
                    self.connectedVPNID = nil
                    self.currentIP = nil
                    self.currentCountryCode = nil
                    self.countryFlag = nil
                }
            }
        }
    }
    
    func fetchLocation() {
        guard !isFetchingLocation else { return }
        isFetchingLocation = true
        
        Task { [weak self] in
            defer {
                Task { @MainActor [weak self] in
                    self?.isFetchingLocation = false
                }
            }
            
            guard let info = await VPNLocationService.shared.fetchCurrentLocation() else {
                return
            }
            
            await MainActor.run { [weak self] in
                guard let self = self, self.connectedVPNID != nil else { return }
                self.currentIP = info.ip
                self.currentCountryCode = info.countryCode
                self.countryFlag = VPNLocationService.flag(for: info.countryCode)
            }
        }
    }
    
    func inferredFlag(for vpn: VPNConfiguration) -> String? {
        if let flag = countryFlag {
            return flag
        }
        if let countryCode = currentCountryCode {
            return VPNLocationService.flag(for: countryCode)
        }
        if let code = VPNLocationService.inferCountryCode(from: vpn.name) {
            return VPNLocationService.flag(for: code)
        }
        return nil
    }
    
    func toggleVPN(_ vpn: VPNConfiguration) {
        let action = vpn.isConnected ? "stop" : "start"
        let uuid = vpn.id
        
        isLoading = true
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
            process.arguments = ["--nc", action, uuid]
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = Pipe()
            
            do {
                try process.run()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                let errorStr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                await MainActor.run {
                    if let err = errorStr, !err.isEmpty {
                        self.connectionError = err
                    } else {
                        self.connectionError = nil
                    }
                    self.refresh()
                }
            } catch {
                await MainActor.run {
                    self.connectionError = error.localizedDescription
                    self.refresh()
                }
            }
        }
    }
}
