//
//  LockScreenLiveActivityOverlayView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/18/26.
//

import SwiftUI

struct LockScreenNotchOverlayView: View {
    let homePageTools: HomePageTools
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var animator: LockScreenLiveActivityAnimator
    
    var body: some View {
        NotchInteractiveBodyView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        .environmentObject(homePageTools)
        .environmentObject(homePageTools.sound)
        .environment(\.notchScale, notchViewModel.notchModel.scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
