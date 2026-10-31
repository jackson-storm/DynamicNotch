//
//  VpnActiveNotchView.swift
//  DynamicNotch
//

import SwiftUI
import Combine

struct VpnActiveNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @ObservedObject var vpnViewModel: VpnViewModel
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString: String = "00:00"
    
    private func updateTimer() {
        guard let startDate = vpnViewModel.vpnConnectedAt else {
            timeString = "00:00"
            return
        }
        let elapsed = Date().timeIntervalSince(startDate)
        timeString = elapsed.formattedDuration
    }
    
    var body: some View {
        HStack {
            if let bandleVpn = vpnViewModel.vpnBundleID, let nsImage = getAppIcon(for: bandleVpn) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isNotchlessScreen ? 24 : 26, height: isNotchlessScreen ? 24 : 26)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text(timeString)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.orange.gradient)
                .monospacedDigit()
        }
        .padding(.leading, isNotchlessScreen ? 5.scaled(by: scale) : 12.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 7.scaled(by: scale) : 14.scaled(by: scale))
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear {
            vpnViewModel.startMonitoring()
            updateTimer()
        }
        .onDisappear {
            vpnViewModel.stopMonitoring()
        }
        .onChange(of: vpnViewModel.vpnConnectedAt) { _, _ in
            updateTimer()
        }
    }
    
    private func getAppIcon(for bundleID: String) -> NSImage? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        let parts = bundleID.components(separatedBy: ".")
        if parts.count > 2 {
            let parentID = parts.dropLast().joined(separator: ".")
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: parentID) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }
        return nil
    }
}
