//
//  NotchController.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import SwiftUI

struct DebugPanelSettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LiveActivityPanelSettingsView(notchViewModel: notchViewModel, notchEventCoordinator: notchEventCoordinator)
                
                TemporaryActivityPanelSettingsView(notchViewModel: notchViewModel, notchEventCoordinator: notchEventCoordinator)
                
                Spacer()
                
                Button(action: {notchViewModel.send(.hide)}) {
                    Text("Hide All Temporary")
                }
            }
            .padding(20)
        }
    }
}

private struct LiveActivityPanelSettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Live Activities Events", systemImage: "dot.radiowaves.left.and.right", color: .blue)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        DebugTitle(title: "Onboarding", icon: "clipboard", color: .orange) {
                            notchEventCoordinator.handleOnboardingEvent(.onboarding)
                        }
                        
                        DebugTitle(title: "AirDrop", icon: "dot.radiowaves.left.and.right", color: .blue) {
                            notchEventCoordinator.handleAirDropEvent(.dragStarted)
                        }
                        
                        DebugTitle(title: "Hotspot", icon: "personalhotspot", color: .green) {
                            notchEventCoordinator.handleNetworkEvent(.hotspotActive)
                        }
                        
                        DebugTitle(title: "Focus on", icon: "moon.fill", color: .indigo) {
                            notchEventCoordinator.handleFocusEvent(.FocusOn)
                        }
                        
                        DebugTitle(title: "Now playing", icon: "speaker.wave.2.fill", color: .red) {
                            notchEventCoordinator.handleNowPlayingEvent(.started)
                        }
                        
                        DebugTitle(title: "Now playing Expanded", icon: "speaker.square.fill", color: .red) {
                            notchViewModel.handleActiveContentTap()
                        }
                        DebugTitle(title: "Lock", icon: "lock.fill", color: .white) {
                            notchEventCoordinator.handleLockScreenEvent(.started)
                        }
                    }
                }
            }
        }
    }
}

private struct TemporaryActivityPanelSettingsView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Temporary Activities Events", systemImage: "bolt.badge.clock", color: .purple)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        DebugTitle(title: "Charger", icon: "bolt.fill", color: .yellow) {
                            notchEventCoordinator.handlePowerEvent(.charger)
                        }
                        DebugTitle(title: "Low Power", icon: "battery.25", color: .red) {
                            notchEventCoordinator.handlePowerEvent(.lowPower)
                        }
                        DebugTitle(title: "Full Power", icon: "battery.100", color: .green) {
                            notchEventCoordinator.handlePowerEvent(.fullPower)
                        }
                        DebugTitle(title: "Bluetooth", icon: "headphones", color: .blue) {
                            notchEventCoordinator.handleBluetoothEvent(.connected)
                        }
                        DebugTitle(title: "Focus off", icon: "moon.fill", color: .indigo) {
                            notchEventCoordinator.handleFocusEvent(.FocusOff)
                        }
                        DebugTitle(title: "VPN", icon: "network", color: .cyan) {
                            notchEventCoordinator.handleNetworkEvent(.vpnConnected)
                        }
                        DebugTitle(title: "WiFi", icon: "wifi", color: .blue) {
                            notchEventCoordinator.handleNetworkEvent(.wifiConnected)
                        }
                        DebugTitle(title: "NotchSizeHeight", icon: "chevron.up.chevron.down", color: .red) {
                            notchEventCoordinator.handleNotchWidthEvent(.height)
                        }
                        DebugTitle(title: "NotchSizeWidth", icon: "chevron.left.chevron.right", color: .red) {
                            notchEventCoordinator.handleNotchWidthEvent(.width)
                        }
                    }
                }
            }
        }
    }
}

private struct SectionHeader: View {
    var title: String
    var systemImage: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }
}

private struct DebugTitle: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 65)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
