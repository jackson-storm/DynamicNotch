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
        if settingsViewModel.isDefaultActivityStrokeEnabled {
            return .white.opacity(0.2)
        }

        switch airDropViewModel.targetedDropTarget {
        case .airDrop:
            return DragAndDropTarget.airDrop.activityStrokeColor

        case .tray:
            return DragAndDropTarget.tray.activityStrokeColor

        case .fileConverter:
            return DragAndDropTarget.fileConverter.activityStrokeColor

        case nil:
            return .white.opacity(0.2)
        }
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 320, height: baseHeight + 110)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 320, height: baseHeight + 110)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            DragAndDropCombinedNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }
}
