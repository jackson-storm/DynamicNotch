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
        if settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isDragAndDropDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        let colorStyle = settingsViewModel.mediaAndFiles.dragAndDropTargetColorStyle

        switch airDropViewModel.targetedDropTarget {
        case .airDrop:
            return DragAndDropTarget.airDrop.activityStrokeColor(for: colorStyle)

        case .fileConverter:
            return DragAndDropTarget.fileConverter.activityStrokeColor(for: colorStyle)

        case .tray:
            return DragAndDropTarget.tray.activityStrokeColor(for: colorStyle)

        case nil:
            return colorStyle == .accent ? .accentColor.opacity(0.3) : .white.opacity(0.2)
        }
    }

    private var targetColorStyle: DragAndDropTargetColorStyle {
        settingsViewModel.mediaAndFiles.dragAndDropTargetColorStyle
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 200, height: baseHeight + 110)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 200, height: baseHeight + 110)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            DragAndDropCombinedNotchView(
                airDropViewModel: airDropViewModel,
                isMotionAnimationEnabled: settingsViewModel.mediaAndFiles.isDropMotionAnimationEnabled,
                targetColorStyle: targetColorStyle
            )
        )
    }
}
