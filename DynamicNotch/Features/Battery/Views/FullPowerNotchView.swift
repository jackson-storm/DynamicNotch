//
//  FullPowerNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FullPowerNotchView: View {
    @ObservedObject var powerService: PowerService
    let style: BatteryNotificationStyle

    @State private var pulse = false
    @State private var showBatteryIndicator = false
    @State private var changeBatteryIndicator = false

    private var batteryColor: Color {
        powerService.isLowPowerMode ? .yellow : .green
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

    var body: some View {
        Group {
            if style == .compact {
                BatteryCompactStatusView(
                    title: "Full Battery",
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

                        if showBatteryIndicator {
                            if powerService.isLowPowerMode {
                                yellowIndicator
                                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                            } else {
                                greenIndicator
                                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                            }
                        } else {
                            magSafeIndicator
                                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .onAppear {
                    showBatteryIndicator = true
                    changeBatteryIndicator = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if showBatteryIndicator {
                            withAnimation(.spring(duration: 0.4)) {
                                showBatteryIndicator = false
                            }
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if changeBatteryIndicator {
                            withAnimation(.spring(duration: 0.2)) {
                                changeBatteryIndicator = false
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        HStack {
            Text(verbatim: "Full Battery")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.semibold)
                .lineLimit(1)

            Text("\(powerService.batteryLevel)%")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(batteryColor)
        }
    }

    @ViewBuilder
    private var description: some View {
        Text(verbatim: "Your Mac is fully charged.")
            .font(.system(size: 10))
            .foregroundStyle(.gray.opacity(0.6))
            .fontWeight(.medium)
            .lineLimit(1)
    }

    @ViewBuilder
    private var greenIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.green.opacity(0.2))
                .frame(width: 70, height: 40)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.4))
                    .frame(width: 44, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 34, height: 14)
                            .opacity(pulse ? 1 : 0.4)
                            .onAppear {
                                startPulse()
                            }
                    )

                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
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
                    .frame(width: 44, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.gradient)
                            .frame(width: 34, height: 14)
                            .opacity(pulse ? 1 : 0.4)
                            .onAppear {
                                startPulse()
                            }
                    )

                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
        }
    }

    @ViewBuilder
    private var magSafeIndicator: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .frame(width: 30, height: 5)

            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.gray.opacity(0.2).gradient)
                    .frame(width: 30, height: 40)

                Circle()
                    .fill(changeBatteryIndicator ? .orange : .green)
                    .shadow(color: changeBatteryIndicator ? .orange : .green, radius: 5)
                    .frame(width: 5, height: 5)
            }

            Rectangle()
                .fill(.white.opacity(0.4))
                .frame(width: 3, height: 32)
        }
    }
}
