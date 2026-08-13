//
//  FocusStatusNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI
internal import AppKit

struct FocusStatusNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isDynamicIsland) var isDynamicIsland

    let title: String
    let tint: Color
    let style: FocusAppearanceStyle
    let icon: String

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
                iconsOnly
                
            case .standard:
                standard
            }
        }
        .foregroundStyle(tint)
        .padding(.leading, isDynamicIsland ? 3.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    private var iconsOnly: some View {
        HStack {
            Image(systemName: resolvedIcon)
                .font(.system(size: 16, weight: .semibold))

            Spacer()
        }
    }
    
    private var standard: some View {
        HStack {
            Image(systemName: resolvedIcon)
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Text(verbatim: title)
                .font(.system(size: 14))
                .padding(.bottom, isDynamicIsland ? 2 : 0)
        }
    }
}
