//
//  FocusOffNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct FocusOffNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Focus.inactive.id
    var priority: Int { NotchContentRegistry.Focus.inactive.priority }
    
    let settingsViewModel: SettingsViewModel
    let focusModeType: FocusModeType
    var appearanceStyle: FocusAppearanceStyle { settingsViewModel.connectivity.focusAppearanceStyle}
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 65, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 50, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOffNotchView(style: appearanceStyle, focusModeType: focusModeType))
    }
}
