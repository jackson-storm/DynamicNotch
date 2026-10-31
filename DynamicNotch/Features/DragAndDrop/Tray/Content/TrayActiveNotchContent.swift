//
//  TrayActiveNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayActiveNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.trayActive.id
    let fileTrayViewModel: FileTrayViewModel
    let mediaSettings: MediaAndFilesSettingsStore
    
    var priority: Int { NotchContentRegistry.DragAndDrop.trayActive.priority }
    var isExpandable: Bool { true }
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 75, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 200, height: baseHeight + 110)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 280, height: baseHeight + 110)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.25
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(TrayActiveNotchView(fileTrayViewModel: fileTrayViewModel))
    }
    
    @MainActor
    func expandedView() -> AnyView {
        AnyView(
            TrayExpandedActiveNotchView(
                fileTrayViewModel: fileTrayViewModel,
                mediaSettings: mediaSettings
            )
        )
    }
}
