//
//  FocusStatusNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FocusOnNotchView: View {
    let style: FocusAppearanceStyle

    var body: some View {
        FocusStatusNotchView(title: "On", tint: .indigo, style: style)
    }
}

struct FocusOffNotchView: View {
    let style: FocusAppearanceStyle

    var body: some View {
        FocusStatusNotchView(title: "Off", tint: .gray.opacity(0.6), style: style)
    }
}

private struct FocusStatusNotchView: View {
    @Environment(\.notchScale) var scale

    let title: String
    let tint: Color
    let style: FocusAppearanceStyle

    var body: some View {
        Group {
            if style == .iconsOnly {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16, weight: .bold))

                    Spacer(minLength: 0)
                }
            } else {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 16, weight: .bold))

                    Spacer()

                    Text(verbatim: title)
                }
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
