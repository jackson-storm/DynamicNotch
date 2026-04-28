//
//  LockScreenNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct LockScreenNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var lockScreenManager: LockScreenManager
    let style: LockScreenStyle

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: lockScreenManager.isShowingLockPresentation ? "lock.fill" : "lock.open.fill")
                .font(.system(size: style == .enlarged ? 16 : 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()

            if style == .enlarged {
                Text(statusTitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, horizontalPadding.scaled(by: scale))
    }
    private var statusTitle: String {
        lockScreenManager.isShowingLockPresentation ? "Locked" : "Unlocked"
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .enlarged:
            18
        case .compact:
            16
        }
    }
}
