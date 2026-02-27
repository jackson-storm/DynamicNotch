//
//  WifiNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import SwiftUI

struct WifiConnectedNotchContent: NotchContentProtocol {
    let id = "wifi.connected"
    let wifiViewModel: WiFiViewModel
    
    var strokeColor: Color { wifiViewModel.isHotspot ? .green.opacity(0.3) : .white.opacity(0.15) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(WifiConnectedNotchView(wifiViewModel: wifiViewModel))
    }
}

struct WifiDisconnectedNotchContent: NotchContentProtocol {
    let id = "wifi.disconnect"
    let wifiViewModel: WiFiViewModel
    
    var strokeColor: Color { .red.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(WifiDisconnectedNotchView(wifiViewModel: wifiViewModel))
    }
}

private struct WifiConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var wifiViewModel: WiFiViewModel
    
    private var iconName: String {
        if !wifiViewModel.isConnected { return "wifi.slash" }
        return wifiViewModel.isHotspot ? "personalhotspot" : "wifi"
    }
    
    private var color: Color {
        if !wifiViewModel.isConnected { return .blue }
        return wifiViewModel.isHotspot ? .green : .blue
    }
    
    private var name: String {
        if !wifiViewModel.isConnected { return "Wi-Fi" }
        return wifiViewModel.isHotspot ? "Hotspot" : "Wi-Fi"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text(name)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("Сonnected")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

private struct WifiDisconnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var wifiViewModel: WiFiViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 44, height: 22)
                    
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("Wi-Fi")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            
            Text("Disconnected")
                .font(.system(size: 14))
                .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.horizontal, 15.scaled(by: scale))
    }
}
