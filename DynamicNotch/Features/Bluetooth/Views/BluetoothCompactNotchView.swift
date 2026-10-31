//
//  BluetoothCompactNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct BluetoothCompactNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    private var batteryIndicatorStyle: BluetoothBatteryIndicatorStyle {
        settings.bluetoothBatteryIndicatorStyle
    }
    
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
        HStack {
            Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                .font(.system(size: 18))
            
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
                } else {
                    Text("---")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.leading, isNotchlessScreen ? 4.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? compactLeadingPadding.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var compactLeadingPadding: CGFloat {
        switch settings.bluetoothBatteryIndicatorStyle {
        case .circle:
            5
        case .percent:
            7
        }
    }
}
