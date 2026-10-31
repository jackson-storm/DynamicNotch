//
//  BluetoothConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct BluetoothConnectedNotchView: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    private var appearanceStyle: BluetoothAppearanceStyle {
        settings.bluetoothAppearanceStyle
    }
    
    var body: some View {
        HStack {
            switch appearanceStyle {
            case .compact:
                BluetoothCompactNotchView(
                    bluetoothViewModel: bluetoothViewModel,
                    settings: settings
                )
                
            case .detailed:
                BluetoothDetailedNotchView(
                    bluetoothViewModel: bluetoothViewModel,
                    settings: settings
                )
            }
        }
    }
}
