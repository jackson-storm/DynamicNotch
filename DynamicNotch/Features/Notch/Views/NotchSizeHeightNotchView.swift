//
//  NotchSizeHeightNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/31/26.
//

import SwiftUI

struct NotchSizeHeightNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.up.chevron.down")
            Spacer()
            AnimatedLevelText(level: settingsViewModel.notchHeight, fontSize: isDynamicIsland ? 16 : 18)
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, isDynamicIsland ? 8.scaled(by: scale) : 16.scaled(by: scale))
    }
}
