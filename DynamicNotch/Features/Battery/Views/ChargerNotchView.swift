//
//  ChargerNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct ChargerNotchView: View {
    @ObservedObject var powerService: PowerService
    
    private var batteryColor: Color {
        if powerService.isLowPowerMode {
            return .yellow
        } else if powerService.batteryLevel <= 20 {
            return .red
        } else {
            return .green
        }
    }
    
    var body: some View {
        BatteryCompactStatusView(
            title: "Charging",
            batteryLevel: powerService.batteryLevel,
            tint: batteryColor
        )
    }
}
