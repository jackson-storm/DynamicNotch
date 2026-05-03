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
    
    private var clampedLevel: Int? {
        bluetoothViewModel.batteryLevel.map { max(0, min(100, $0)) }
    }
    
    private func tint(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            switch appearanceStyle {
            case .compact:
                compactView
                
            case .detailed:
                detailedView
            }
        }
        .font(.system(size: 14))
    }
    
    @ViewBuilder
    private var compactView: some View {
        HStack {
            Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            switch batteryIndicatorStyle {
            case .circle:
                BluetoothBatteryIndicatorView(
                    batteryLevel: bluetoothViewModel.batteryLevel,
                    circleSize: 18,
                    circleLineWidth: 3,
                    usesTintedTrackStroke: isBatteryStrokeActive
                )
                
            case .percent:
                if let clampedLevel {
                    Text("\(String(describing: clampedLevel))%")
                        .foregroundStyle(tint(for: clampedLevel).gradient)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14.scaled(by: scale))
    }
    
    @ViewBuilder
    private var detailedView: some View {
        VStack {
            Spacer()
            
            HStack {
                HStack(spacing: 16) {
                    Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 10)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: "Connected")
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
                            frameWidth: 150.scaled(by: scale)
                        )
                    }
                }
                
                Spacer()
                
                ZStack {
                    BluetoothBatteryIndicatorView(
                        batteryLevel: bluetoothViewModel.batteryLevel,
                        circleSize: 40,
                        circleLineWidth: 4,
                        usesTintedTrackStroke: isBatteryStrokeActive
                    )
                    if let clampedLevel {
                        Text(String(describing: clampedLevel))
                            .font(.system(size: 14))
                            .foregroundStyle(tint(for: clampedLevel))
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .padding(.horizontal, 38)
        .padding(.bottom, 10)
    }
}
