//
//  NotchController.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import SwiftUI

struct DebugPanel: View {
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
                
                // --- ACTIVE SECTION ---
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "Live Active Event", systemImage: "dot.radiowaves.left.and.right", color: .blue)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        debugTile(title: "Onboarding", icon: "clipboard", color: .orange) {
                            notchEventCoordinator.handleOnboardingEvent(.onboarding)
                        }
                        
                        debugTile(title: "AirDrop", icon: "dot.radiowaves.left.and.right", color: .blue) {
                            notchEventCoordinator.handleAirDropEvent(.dragStarted)
                        }
                        
                        debugTile(title: "Hotspot", icon: "personalhotspot", color: .green) {
                            notchEventCoordinator.handleNetworkEvent(.hotspotActive)
                        }
                        debugTile(title: "Focus on", icon: "moon.fill", color: .indigo) {
                            notchEventCoordinator.handleDoNotDisturbEvent(.FocusOn)
                        }
                    }
                }
                
                Divider().opacity(0.5)
                
                // --- TEMPORARY SECTION ---
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "Temporary Events", systemImage: "bolt.badge.clock", color: .purple)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        debugTile(title: "Charger", icon: "bolt.fill", color: .yellow) {
                            notchEventCoordinator.handlePowerEvent(.charger)
                        }
                        debugTile(title: "Low Power", icon: "battery.25", color: .red) {
                            notchEventCoordinator.handlePowerEvent(.lowPower)
                        }
                        debugTile(title: "Full Power", icon: "battery.100", color: .green) {
                            notchEventCoordinator.handlePowerEvent(.fullPower)
                        }
                        debugTile(title: "Bluetooth", icon: "headphones", color: .blue) {
                            notchEventCoordinator.handleBluetoothEvent(.connected)
                        }
                        debugTile(title: "Focus off", icon: "moon.fill", color: .indigo) {
                            notchEventCoordinator.handleDoNotDisturbEvent(.FocusOff)
                        }
                        debugTile(title: "VPN", icon: "network", color: .cyan) {
                            notchEventCoordinator.handleNetworkEvent(.vpnConnected)
                        }
                        debugTile(title: "WiFi", icon: "wifi", color: .blue) {
                            notchEventCoordinator.handleNetworkEvent(.wifiConnected)
                        }
                    }
                }
            }
            Spacer()
            
            Button(action: {notchViewModel.send(.hide)}) {
                Text("Hide All Temporary")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func sectionHeader(title: String, systemImage: String, color: Color) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }
    
    @ViewBuilder
    private func debugTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
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
