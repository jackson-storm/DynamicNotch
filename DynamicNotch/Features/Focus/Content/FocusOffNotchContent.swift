//
//  FocusOffNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

internal import AppKit
import SwiftUI

struct FocusOffNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Focus.inactive.id
    var priority: Int { NotchContentRegistry.Focus.inactive.priority }

    let settingsViewModel: SettingsViewModel
    let focusModeType: FocusModeType
    var appearanceStyle: FocusAppearanceStyle { settingsViewModel.connectivity.focusAppearanceStyle }
    var isExpandable: Bool { true }

    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        focusModeType.tint.opacity(0.3)
    }

    var windowLink: (@MainActor () -> Void)? {
        return {
            Self.openFocusSettings()
        }
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
        AnyView(FocusOffNotchView(style: appearanceStyle, focusModeType: focusModeType))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(FocusOffExpandedNotchView(focusModeType: focusModeType))
    }

    @MainActor
    private static func openFocusSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
