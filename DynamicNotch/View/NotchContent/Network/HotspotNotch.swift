//
//  HotspotNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/27/26.
//

import SwiftUI

struct HotspotConnectedContent: NotchContentProtocol {
    let id = "hotspot.connected"
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotConnectedView())
    }
}

struct HotspotDisconnectedNotchContent: NotchContentProtocol {
    let id = "hotspot.disconnected"
    
    var strokeColor: Color { .red.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 220, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotDisconnectedNotchView())
    }
}

struct HotspotActiveContent: NotchContentProtocol {
    let id = "hotspot.active"
    
    var strokeColor: Color { .green.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 80, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(HotspotActiveNotchView())
    }
}

private struct HotspotConnectedView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.green)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("Hotspot")
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

private struct HotspotDisconnectedNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 44, height: 22)
                    
                    Image(systemName: "personalhotspot.slash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("Hotspot")
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

private struct HotspotActiveNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
