//
//  FocusOnNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

internal import AppKit
import SwiftUI

struct FocusOnNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Focus.active.id
    let settingsViewModel: SettingsViewModel
    let focusModeType: FocusModeType

    var priority: Int { NotchContentRegistry.Focus.active.priority }
    var isExpandable: Bool { true }
    var appearanceStyle: FocusAppearanceStyle {
        settingsViewModel.connectivity.focusAppearanceStyle
    }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        focusModeType.tint.opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 65, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 140, height: baseHeight + 60)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 40)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 30, height: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight + 50)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(FocusOnNotchView(style: appearanceStyle, focusModeType: focusModeType))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(FocusOnExpandedNotchView(focusModeType: focusModeType))
    }
}
