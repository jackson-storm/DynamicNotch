//
//  LockScreenLiveActivityOverlayView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/18/26.
//

import SwiftUI

struct LockScreenNotchOverlayView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var animator: LockScreenLiveActivityAnimator
    
    var body: some View {
        NotchInteractiveBodyView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        .environment(\.notchScale, notchViewModel.notchModel.scale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
