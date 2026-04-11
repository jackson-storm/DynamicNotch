//
//  WifiNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import SwiftUI

struct WifiConnectedNotchContent: NotchContentProtocol {
    let id = "wifi.connected"
    let networkViewModel: NetworkViewModel
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            WifiConnectedNotchView(
                networkViewModel: networkViewModel
            )
        )
    }
}

private struct WifiConnectedNotchView: View {
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
            Image(systemName: "wifi")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor.gradient)
                .contentTransition(.symbolEffect(.replace))
            
            Text(verbatim: "Wi-Fi")
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var rightContent: some View {
        Text(verbatim: "Connected")
            .foregroundStyle(.white.opacity(0.8))
    }
}
