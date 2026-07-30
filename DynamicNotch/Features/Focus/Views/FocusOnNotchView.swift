//
//  FocusOnNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/30/26.
//

import SwiftUI
internal import AppKit

struct FocusOnNotchView: View {
    @ObservedObject private var manager = DoNotDisturbManager.shared
    
    let style: FocusAppearanceStyle
    let focusModeType: FocusModeType

    private var activeFocusModeType: FocusModeType {
        if manager.isDoNotDisturbActive {
            return FocusModeType.resolve(
                identifier: manager.currentFocusModeIdentifier,
                name: manager.currentFocusModeName
            )
        }
        return focusModeType
    }

    var body: some View {
        FocusStatusNotchView(title: "On", tint: activeFocusModeType.tint, style: style, icon: activeFocusModeType.icon)
    }
}
