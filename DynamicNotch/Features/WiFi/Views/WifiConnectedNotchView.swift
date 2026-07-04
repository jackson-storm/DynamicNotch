//
//  WifiConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct WifiConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    @ObservedObject var wifiViewModel: WifiViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            AnimatedWifiIcon(targetLevel: wifiViewModel.wifiSignalLevel)
                .frame(width: 20, height: 18)
            
            Spacer()
            
            Text(verbatim: "Active")
                .foregroundStyle(.white)
        }
        .font(.system(size: 14))
        .padding(.horizontal, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.vertical, 10)
    }
}

private struct AnimatedWifiIcon: View {
    let targetLevel: Double

    @State private var signalLevel = 0.0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: "wifi", variableValue: signalLevel)
            .font(.system(size: 18, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.white)
            .animation(.snappy(duration: 0.22, extraBounce: 0.08), value: signalLevel)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }

    private func startAnimation() { 
        animationTask?.cancel()

        animationTask = Task { @MainActor in
            signalLevel = 0
            await play(levels: [0.18, 0.44, 0.72, 1.0])

            guard !Task.isCancelled else { return }

            signalLevel = 0
            await play(levels: levels(upTo: targetLevel))

            animationTask = nil
        }
    }

    private func play(levels: [Double]) async {
        for level in levels {
            guard !Task.isCancelled else { return }

            withAnimation(.snappy(duration: 0.22, extraBounce: 0.08)) {
                signalLevel = level
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
        }
    }

    private func levels(upTo targetLevel: Double) -> [Double] {
        let target = min(max(targetLevel, 0.08), 1)
        let steps = [0.18, 0.44, 0.72].filter { $0 < target }
        return steps + [target]
    }
}
