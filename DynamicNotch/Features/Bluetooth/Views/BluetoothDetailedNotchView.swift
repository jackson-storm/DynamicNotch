//
//  BluetoothDetailedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct BluetoothDetailedNotchView: View {
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @Environment(\.locale) var locale
    
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    private var isBatteryStrokeActive: Bool {
        settings.isBluetoothBatteryStrokeEnabled
    }
    
    private var clampedLevel: Int? {
        bluetoothViewModel.batteryLevel.map { max(0, min(100, $0)) }
    }
    
    private func tint(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 16) {
            deviceImage
            description
                .padding(.top, isNotchlessScreen ? 15 : 0)
            Spacer()
            indicator
        }
        .padding(.bottom, isNotchlessScreen ? 0 : 25)
        .padding(.leading, isNotchlessScreen ? 15 : 38)
        .padding(.trailing, isNotchlessScreen ? 15 : 38)
    }
    
    private var deviceImage: some View {
        Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
            .font(.system(size: 30))
            .foregroundStyle(.white)
    }
    
    private var description: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(locale.dn("notch.bluetooth.connected", fallback: "Connected"))
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
            
            MarqueeText(
                $bluetoothViewModel.deviceName,
                font: .system(size: 15, weight: .regular),
                nsFont: .body,
                textColor: .white.opacity(0.8),
                backgroundColor: .clear,
                minDuration: 0.5,
                frameWidth: 150
            )
        }
    }
    
    private var indicator: some View {
        ZStack {
            BluetoothBatteryIndicatorView(
                batteryLevel: bluetoothViewModel.batteryLevel,
                circleSize: 45,
                circleLineWidth: 5.0,
                usesTintedTrackStroke: isBatteryStrokeActive
            )
            if let clampedLevel {
                Text(String(describing: clampedLevel))
                    .font(.system(size: 16))
                    .foregroundStyle(tint(for: clampedLevel))
            }
        }
    }
}
