//
//  FocusOffNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/30/26.
//

import SwiftUI
internal import AppKit

struct FocusOffNotchView: View {
    let style: FocusAppearanceStyle
    let focusModeType: FocusModeType

    var body: some View {
        FocusStatusNotchView(title: "Off", tint: .gray.opacity(0.6), style: style, icon: focusModeType.icon)
    }
}
