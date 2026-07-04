//
//  LowPowerNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LowPowerNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var powerService: PowerService
    @State private var pulse = false
    
    let style: BatteryNotificationStyle

    var body: some View {
        Group {
            if style == .compact {
                BatteryCompactStatusView(
                    title: "Low Battery",
                    batteryLevel: powerService.batteryLevel,
                    tint: batteryColor
                )
            } else {
                VStack {
                    Spacer()

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            title
                            description
                        }

                        Spacer()

                        if powerService.isLowPowerMode {
                            yellowIndicator
                        } else {
                            redIndicator
                        }
                    }
                }
                .padding(.bottom, isDynamicIsland ? 20 : 20)
                .padding(.horizontal, isDynamicIsland ? 25 : 45)
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        HStack {
            Text(verbatim: "Battery Low")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(powerService.batteryLevel)%")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(batteryColor)
        }
    }

    @ViewBuilder
    private var description: some View {
        if powerService.isLowPowerMode {
            Text(verbatim: "Low Power Mode enabled")
                .foregroundColor(.yellow)
                .font(.system(size: 11, weight: .medium))

            + Text(verbatim: ", it is recommended to charge it.")
                .foregroundColor(.gray.opacity(0.55))
                .font(.system(size: 11, weight: .medium))
        } else {
            Text(verbatim: "Turn on Low Power Mode or it \nis recommended to charge it.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray.opacity(0.55))
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var redIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.red.opacity(0.2))
                .frame(width: 70, height: 40)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.4))
                    .frame(width: 40, height: 24)

                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
            .padding(.trailing, 5)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.gradient)
                .frame(width: 8, height: 14)
                .opacity(pulse ? 1 : 0.3)
                .offset(x: -15)
                .onAppear { startPulse() }

            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.red.opacity(0.9).gradient, lineWidth: 1.5)
                .frame(width: pulse ? 8 : 30, height: pulse ? 14 : 32)
                .offset(x: -15)
                .opacity(pulse ? 0.3 : 1)
        }
    }

    @ViewBuilder
    private var yellowIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.yellow.opacity(0.2))
                .frame(width: 70, height: 40)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 40, height: 24)

                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
            .padding(.trailing, 5)

            RoundedRectangle(cornerRadius: 8)
                .fill(.yellow.gradient)
                .frame(width: 8, height: 14)
                .offset(x: -15)
        }
    }
    
    private var batteryColor: Color {
        powerService.isLowPowerMode ? .yellow : .red
    }

    private func startPulse() {
        pulse = false
        withAnimation(
            .easeInOut(duration: 1)
            .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }
}
