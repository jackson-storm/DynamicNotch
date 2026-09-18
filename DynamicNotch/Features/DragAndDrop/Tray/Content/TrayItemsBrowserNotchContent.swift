//
//  TrayItemsBrowserNotchContent.swift
//  DynamicNotch
//

import SwiftUI

struct TrayItemsBrowserNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.trayItemsBrowser.id
    let fileTrayViewModel: FileTrayViewModel
    let mediaSettings: MediaAndFilesSettingsStore

    var priority: Int { NotchContentRegistry.DragAndDrop.trayItemsBrowser.priority }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 208, height: baseHeight + 120)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 260, height: baseHeight + 120)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            TrayExpandedActiveNotchView(
                fileTrayViewModel: fileTrayViewModel,
                mediaSettings: mediaSettings
            )
        )
    }
}
