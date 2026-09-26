//
//  LockScreenNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var lockScreenManager: LockScreenManager
    
    let style: LockScreenStyle

    var body: some View {
        HStack {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: isNotchlessScreen ? 14 : 16, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()

            if style == .enlarged {
                Text(verbatim: lockScreenManager.isShowingLockPresentation ? "Locked" : "Unlocked")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, isNotchlessScreen ? 6.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
