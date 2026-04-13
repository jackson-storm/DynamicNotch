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
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isFocusDefaultStrokeEnabled ?
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
