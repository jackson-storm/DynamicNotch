//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectView: View {
    @ObservedObject var networkViewModel: NetworkViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(networkViewModel.isConnected ? .blue.opacity(0.2) : .red.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: networkViewModel.isConnected ? "network.badge.shield.half.filled" : "network.slash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(networkViewModel.isConnected ? .blue : .red)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("VPN")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.leading, 16)
            
            Spacer()
            
            Text(networkViewModel.isConnected ? "Сonnected" : "Disconnected")
                .font(.system(size: 14))
                .foregroundStyle(networkViewModel.isConnected ? .white : .red)
                .padding(.trailing, 20)
        }
    }
}


#Preview {
    ZStack(alignment: .top) {
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .fill(.black)
            .stroke(.white.opacity(0.1), lineWidth: 1)
            .overlay{VpnConnectView(networkViewModel: NetworkViewModel())}
            .frame(width: 400, height: 38)
        
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .stroke(.red)
            .frame(width: 226, height: 38)
    }
    .frame(width: 450, height: 100, alignment: .top)
}
