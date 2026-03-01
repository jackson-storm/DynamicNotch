//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectedNotchContent : NotchContentProtocol {
    let id = "vpn.connected"
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(VpnConnectView())
    }
}

private struct VpnConnectView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("VPN")
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
