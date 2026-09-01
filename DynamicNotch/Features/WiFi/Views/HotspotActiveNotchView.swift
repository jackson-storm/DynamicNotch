//
//  HotspotActiveNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct HotspotActiveNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let style: HotspotAppearanceStyle
    @ObservedObject var wifiViewModel: WifiViewModel
    var batteryLevel: Int? = nil
    
    init(style: HotspotAppearanceStyle, wifiViewModel: WifiViewModel? = nil, batteryLevel: Int? = nil) {
        self.style = style
        self._wifiViewModel = ObservedObject(wrappedValue: wifiViewModel ?? WifiViewModel())
        self.batteryLevel = batteryLevel
    }
    
    private var displayBatteryLevel: Int {
        let level = wifiViewModel.hotspotBatteryLevel ?? batteryLevel
        if let level {
            return max(0, min(100, level))
        }
        return 100
    }
    
    private func tint(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            switch style {
            case .minimal:
                minimal
                
            case .detailed:
                detailed

            case .battery:
                batteryView
            }
        }
        .font(.system(size: 14))
        .padding(.leading, isDynamicIsland ? 4.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var minimal: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
        }
    }
    
    private var detailed: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
            
            Text(verbatim: "On")
                .font(.system(size: 14))
                .foregroundStyle(.green)
        }
    }

    private var batteryView: some View {
        HStack {
            Image(systemName: "personalhotspot")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
            
            Spacer()
            
            Text("\(displayBatteryLevel)%")
                .font(.system(size: 14))
                .foregroundStyle(tint(for: displayBatteryLevel).gradient)
        }
    }
}
