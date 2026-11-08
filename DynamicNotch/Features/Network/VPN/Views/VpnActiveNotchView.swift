//
//  VpnActiveNotchView.swift
//  DynamicNotch
//

import SwiftUI

struct VpnActiveNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @ObservedObject var vpnViewModel: VpnViewModel

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

            if let startDate = vpnViewModel.vpnConnectedAt {
                TimelineView(.periodic(from: scheduleStart(startDate: startDate), by: 1)) { context in
                    timeText(at: context.date, startDate: startDate)
                }
            } else {
                Text("0:00")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.orange.gradient)
                    .monospacedDigit()
            }
        }
        .padding(.leading, isNotchlessScreen ? 5.scaled(by: scale) : 12.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 7.scaled(by: scale) : 14.scaled(by: scale))
        .onAppear {
            vpnViewModel.startMonitoring()
        }
        .onDisappear {
            vpnViewModel.stopMonitoring()
        }
    }

    private func scheduleStart(startDate: Date) -> Date {
        let now = Date.now
        let elapsed = max(0, now.timeIntervalSince(startDate))
        let wholeSeconds = elapsed.rounded(.down)
        let tickDate = startDate.addingTimeInterval(wholeSeconds)
        return tickDate <= now ? tickDate : now
    }

    private func timeText(at date: Date, startDate: Date) -> some View {
        let elapsed = max(0, Int(date.timeIntervalSince(startDate)))
        let formatted = Self.formattedTime(elapsed)

        return Text(formatted)
            .font(.system(size: 14, design: .rounded))
            .foregroundStyle(.orange.gradient)
            .monospacedDigit()
    }

    static func formattedTime(_ seconds: Int) -> String {
        if let abbreviated = TimerSource.abbreviatedTime(seconds) {
            return abbreviated
        }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
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
