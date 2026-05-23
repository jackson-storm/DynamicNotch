//
//  FocusStatusNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FocusOnNotchView: View {
    let style: FocusAppearanceStyle
    let focusModeType: FocusModeType

    var body: some View {
        FocusStatusNotchView(title: "On", tint: focusModeType.tint, style: style, icon: focusModeType.icon)
    }
}

struct FocusOffNotchView: View {
    let style: FocusAppearanceStyle
    let focusModeType: FocusModeType

    var body: some View {
        FocusStatusNotchView(title: "Off", tint: .gray.opacity(0.6), style: style, icon: focusModeType.icon)
    }
}

private struct FocusStatusNotchView: View {
    @Environment(\.notchScale) var scale

    let title: String
    let tint: Color
    let style: FocusAppearanceStyle
    let icon: String

    var body: some View {
        Group {
            if style == .iconsOnly {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))

                    Spacer(minLength: 0)
                }
            } else {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))

                    Spacer(minLength: 10)

                    Text(verbatim: title)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
