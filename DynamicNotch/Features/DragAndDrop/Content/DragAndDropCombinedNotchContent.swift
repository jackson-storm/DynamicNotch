//
//  DragAndDropCombinedNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct DragAndDropCombinedNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.combined.id

    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel

    var priority: Int { NotchContentRegistry.DragAndDrop.combined.priority }

    var strokeColor: Color {
        switch airDropViewModel.targetedDropTarget {
        case .airDrop:
            return DragAndDropTarget.airDrop.activityStrokeColor

        case .tray:
            return DragAndDropTarget.tray.activityStrokeColor

        case nil:
            return .white.opacity(0.2)
        }
    }

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 200, height: baseHeight + 110)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.25
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            DragAndDropCombinedNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }
}
