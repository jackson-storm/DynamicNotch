//
//  BluetoothConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct BluetoothConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private var appearanceStyle: BluetoothAppearanceStyle {
        settings.bluetoothAppearanceStyle
    }

    private var batteryIndicatorStyle: BluetoothBatteryIndicatorStyle {
        settings.bluetoothBatteryIndicatorStyle
    }

    private var isBatteryStrokeActive: Bool {
        settings.isBluetoothBatteryStrokeEnabled && applicationSettings.isDefaultActivityStrokeEnabled == false
    }
    
    var body: some View {
        HStack {
            leftContent
            Spacer()
            rightContent
        }
        .padding(.horizontal, 14.scaled(by: scale))
        .font(.system(size: 14))
    }
    
    @ViewBuilder
    private var leftContent: some View {
        switch appearanceStyle {
        case .device:
            Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.8))
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))

        case .detailed:
            MarqueeText(
                $bluetoothViewModel.deviceName,
                font: .system(size: 14),
                nsFont: .body,
                textColor: .white.opacity(0.8),
                backgroundColor: .clear,
                minDuration: 0.5,
                frameWidth: 90
            )
            .lineLimit(1)
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .trailing)))
        }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        switch appearanceStyle {
        case .device:
            HStack(spacing: 8) {
                BluetoothBatteryIndicatorView(
                    batteryLevel: bluetoothViewModel.batteryLevel,
                    indicatorStyle: batteryIndicatorStyle,
                    circleSize: 18,
                    circleLineWidth: 3,
                    usesTintedTrackStroke: isBatteryStrokeActive
                )
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))

        case .detailed:
            HStack(spacing: 6) {
                BluetoothBatteryIndicatorView(
                    batteryLevel: bluetoothViewModel.batteryLevel,
                    indicatorStyle: batteryIndicatorStyle,
                    circleSize: 18,
                    circleLineWidth: 3,
                    usesTintedTrackStroke: isBatteryStrokeActive
                )

                Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))
        }
    }
}
