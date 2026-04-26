//
//  WifiConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct WifiConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var networkViewModel: NetworkViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            leftContent
            Spacer(minLength: 10)
            rightContent
        }
        .font(.system(size: 14))
        .padding(.horizontal, 14.scaled(by: scale))
    }
    
    @ViewBuilder
    private var leftContent: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.gradient.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "wifi")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor.gradient)
                    .contentTransition(.symbolEffect(.replace))
            }
            Text(verbatim: "Wi-Fi")
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var rightContent: some View {
        Text(verbatim: "Connected")
            .foregroundStyle(.white.opacity(0.8))
    }
}
