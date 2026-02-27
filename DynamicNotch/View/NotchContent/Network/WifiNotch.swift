//
//  WifiNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import SwiftUI

struct WifiConnectedNotchContent: NotchContentProtocol {
    let id = "wifi.connected"
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(WifiConnectedNotchView())
    }
}

struct WifiDisconnectedNotchContent: NotchContentProtocol {
    let id = "wifi.disconnect"
    
    var strokeColor: Color { .red.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(WifiDisconnectedNotchView())
    }
}

private struct WifiConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "wifi")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("Wi-Fi")
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
