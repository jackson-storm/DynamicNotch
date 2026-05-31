//
//  Do.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI

struct FocusOnNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Focus.active.id
    let settingsViewModel: SettingsViewModel
    let focusModeType: FocusModeType

    var appearanceStyle: FocusAppearanceStyle {
        settingsViewModel.connectivity.focusAppearanceStyle
    }
    var priority: Int { NotchContentRegistry.Focus.active.priority }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.connectivity.isFocusDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        focusModeType.tint.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 65, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 50, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOnNotchView(style: appearanceStyle, focusModeType: focusModeType))
    }
}
