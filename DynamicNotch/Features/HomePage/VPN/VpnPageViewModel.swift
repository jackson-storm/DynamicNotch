//
//  VpnPageViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class VpnPageViewModel: ObservableObject {
    @Published var vpns: [VPNConfiguration] = []
    @Published var isLoading: Bool = false
    @Published var connectionError: String? = nil
    @Published var connectedAt: Date? = nil
    
    private var refreshTimer: Timer?
    
    func startMonitoring() {
        refresh()
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
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let list = VPNStatusFetcher.fetchVPNs()
            
            var connDate: Date? = nil
            let selectedID = UserDefaults.standard.string(forKey: "settings.vpn.selectedID") ?? ""
            if let selectedVpn = list.first(where: { $0.id == selectedID }), selectedVpn.isConnected {
                connDate = VPNStatusFetcher.fetchVPNConnectedAt(uuid: selectedVpn.id)
            } else if let activeVpn = list.first(where: { $0.isConnected }) {
                connDate = VPNStatusFetcher.fetchVPNConnectedAt(uuid: activeVpn.id)
            }
            
            let finalConnDate = connDate
            await MainActor.run {
                self.vpns = list
                self.isLoading = false
                self.connectedAt = finalConnDate
            }
        }
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
