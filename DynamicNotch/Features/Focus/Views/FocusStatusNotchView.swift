//
//  FocusStatusNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
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

struct FocusOffNotchView: View {
    let style: FocusAppearanceStyle
    let focusModeType: FocusModeType

    var body: some View {
        FocusStatusNotchView(title: "Off", tint: .gray.opacity(0.6), style: style, icon: focusModeType.icon)
    }
}

private struct FocusStatusNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland

    let title: String
    let tint: Color
    let style: FocusAppearanceStyle
    let icon: String

    // A custom Focus mode can reference a symbol that isn't a valid SF Symbol on
    // this system (or the name may be missing when Full Disk Access is denied and
    // the mode's metadata can't be read). `Image(systemName:)` renders those as an
    // empty square, so fall back to a focus glyph when the name doesn't resolve.
    private var resolvedIcon: String {
        if NSImage(systemSymbolName: icon, accessibilityDescription: nil) != nil {
            return icon
        }
        return "moon.fill"
    }

    var body: some View {
        Group {
            switch style {
            case .iconsOnly:
                HStack {
                    Image(systemName: resolvedIcon)
                        .font(.system(size: 16, weight: .bold))

                    Spacer()
                }
            case .standard:
                HStack {
                    Image(systemName: resolvedIcon)
                        .font(.system(size: 16, weight: .bold))

                    Spacer()

                    Text(verbatim: title)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
}
