//
//  Do.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI

struct FocusOnNotchContent: NotchContentProtocol {
    let id = "focus.on"
    let settingsViewModel: SettingsViewModel

    private var appearanceStyle: FocusAppearanceStyle {
        settingsViewModel.connectivity.focusAppearanceStyle
    }
    
    var priority: Int { 60 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .indigo.opacity(0.3)
    }
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(
            width: baseWidth + (appearanceStyle == .standard ? 65 : 65),
            height: baseHeight
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOnNotchView(style: appearanceStyle))
    }
}

struct FocusOffNotchContent: NotchContentProtocol {
    let id = "focus.off"
    let settingsViewModel: SettingsViewModel

    private var appearanceStyle: FocusAppearanceStyle {
        settingsViewModel.connectivity.focusAppearanceStyle
    }
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .gray.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(
            width: baseWidth + (appearanceStyle == .standard ? 65 : 65),
            height: baseHeight
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOffNotchView(style: appearanceStyle))
    }
}

private struct FocusOnNotchView: View {
    let style: FocusAppearanceStyle

    var body: some View {
        FocusStatusNotchView(title: "On", tint: .indigo, style: style)
    }
}

private struct FocusOffNotchView: View {
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
