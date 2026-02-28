//
//  NotchController.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/15/26.
//

import SwiftUI

struct NotchControlPanel: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchEventCoordinator: NotchEventCoordinator

    var body: some View {
        GroupBox {
            VStack(alignment: .center, spacing: 15) {
                activeSection
                Divider()
                temporarySection
                Spacer()
            }
            .padding(8)
        }
        .padding()
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }
    
    @ViewBuilder
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Active", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
            
            HStack(spacing: 8) {
                Button {
                    notchEventCoordinator.handleOnboardingEvent(.onboarding)
                } label: {
                    Label("Onboarding", systemImage: "clipboard")
                }
            }
        }
    }
    
    @ViewBuilder
    private var temporarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Temporary", systemImage: "bolt.badge.clock")
                .font(.headline)
            
            // Power
            ControlGroup {
                Button {
                    notchEventCoordinator.handlePowerEvent(.charger)
                } label: {
                    Label("Charger", systemImage: "bolt.fill")
                }
                
                Button {
                    notchEventCoordinator.handlePowerEvent(.lowPower)
                } label: {
                    Label("Low Power", systemImage: "battery.25")
                }
                
                Button {
                    notchEventCoordinator.handlePowerEvent(.fullPower)
                } label: {
                    Label("Full Power", systemImage: "battery.100")
                }
            }
            .controlGroupStyle(.automatic)
            
            // Bluetooth / VPN / HUD
            ControlGroup {
                Button {
                    notchEventCoordinator.handleBluetoothEvent(.connected)
                } label: {
                    Label("Bluetooth", systemImage: "headphones")
                }
                
//                Button {
//                    notchEventCoordinator.handleHudEvent(.volume)
//                } label: {
//                    Label("Volume", systemImage: "speaker.wave.3.fill")
//                }
//                
//                Button {
//                    notchEventCoordinator.handleHudEvent(.display)
//                } label: {
//                    Label("Display", systemImage: "sun.max.fill")
//                }
//                
//                Button {
//                    notchEventCoordinator.handleHudEvent(.keyboard)
//                } label: {
//                    Label("Keyboard", systemImage: "light.max")
//                }
            }
            .controlGroupStyle(.automatic)
            
            ControlGroup {
                Button {
                    notchEventCoordinator.handleNetworkEvent(.vpnConnected)
                } label: {
                    Label("Vpn Connected", systemImage: "network")
                }
                
                Button {
                    notchEventCoordinator.handleNetworkEvent(.wifiConnected)
                } label: {
                    Label("WiFi Connected", systemImage: "wifi")
                }
            }
            .controlGroupStyle(.automatic)
            
            HStack {
                Button {
                    notchViewModel.send(.hide)
                } label: {
                    Label("Hide temporary", systemImage: "eye.slash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
}
