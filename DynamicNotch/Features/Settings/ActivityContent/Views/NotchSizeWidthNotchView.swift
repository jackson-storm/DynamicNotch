//
//  NotchSizeWidthNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/31/26.
//

import SwiftUI

struct NotchSizeWidthNotchView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                AnimatedLevelText(level: settingsViewModel.notchWidth, fontSize: isNotchlessScreen ? 16 : 18)
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .font(.system(size: 18))
        .foregroundColor(.white)
        .padding(.horizontal, isNotchlessScreen ? 12.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.bottom, 10)
    }
}
