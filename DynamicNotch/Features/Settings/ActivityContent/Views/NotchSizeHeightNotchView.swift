//
//  NotchSizeHeightNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/31/26.
//

import SwiftUI

struct NotchSizeHeightNotchView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.up.chevron.down")
            Spacer()
            AnimatedLevelText(level: settingsViewModel.notchHeight, fontSize: isNotchlessScreen ? 16 : 18)
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, isNotchlessScreen ? 8.scaled(by: scale) : 16.scaled(by: scale))
    }
}
