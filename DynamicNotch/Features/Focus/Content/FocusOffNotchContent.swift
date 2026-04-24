//
//  FocusOffNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FocusOffNotchContent: NotchContentProtocol {
    let id = "focus.off"
    
    let settingsViewModel: SettingsViewModel
    private var appearanceStyle: FocusAppearanceStyle { settingsViewModel.connectivity.focusAppearanceStyle}
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isFocusDefaultStrokeEnabled ?
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
