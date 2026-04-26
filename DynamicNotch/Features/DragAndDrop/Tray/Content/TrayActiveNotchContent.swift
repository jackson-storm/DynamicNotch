//
//  TrayActiveNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/26/26.
//

import SwiftUI

struct TrayActiveNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.DragAndDrop.trayActive.id

    let fileTrayViewModel: FileTrayViewModel
    
    var priority: Int { NotchContentRegistry.DragAndDrop.trayActive.priority }
    var isExpandable: Bool { true }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 65, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 208, height: baseHeight + 115)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(TrayActiveNotchView(fileTrayViewModel: fileTrayViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(TrayExpandedActiveNotchView(fileTrayViewModel: fileTrayViewModel))
    }
}
