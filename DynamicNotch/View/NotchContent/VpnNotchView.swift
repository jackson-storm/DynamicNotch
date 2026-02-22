//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectView: View {
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
        .padding(.horizontal, 18)
    }
}

struct VpnDisconnectView: View {
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 44, height: 20)
                    
                    Image(systemName: "network.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("VPN")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            
            Text("Disconnected")
                .font(.system(size: 14))
                .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.horizontal, 18)
    }
}

#Preview {
    VStack(spacing: 30) {
        ZStack(alignment: .top) {
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .overlay{ VpnConnectView() }
                .frame(width: 400, height: 38)
            
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .stroke(.red)
                .frame(width: 226, height: 38)
        }
        
        ZStack(alignment: .top) {
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .overlay{ VpnDisconnectView() }
                .frame(width: 440, height: 38)
            
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .stroke(.red)
                .frame(width: 226, height: 38)
        }
    }
    .frame(width: 450, height: 150, alignment: .top)
}
