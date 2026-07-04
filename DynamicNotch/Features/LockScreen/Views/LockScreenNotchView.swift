//
//  LockScreenNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var lockScreenManager: LockScreenManager
    
    let style: LockScreenStyle

    var body: some View {
        HStack {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: isDynamicIsland ? 14 : 16, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()

            if style == .enlarged {
                Text(verbatim: lockScreenManager.isShowingLockPresentation ? "Locked" : "Unlocked")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, isDynamicIsland ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
