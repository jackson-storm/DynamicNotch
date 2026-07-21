//
//  FileConverterContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/7/26.
//

import SwiftUI

struct FileConverterNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.DragAndDrop.fileConverter.id

    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel

    var priority: Int { NotchContentRegistry.DragAndDrop.fileConverter.priority }

    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        DragAndDropTarget.fileConverter.activityStrokeColor(for: settingsViewModel.mediaAndFiles.dragAndDropTargetColorStyle)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight + 110)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            FileConverterNotchView(
                airDropViewModel: airDropViewModel,
                targetColorStyle: settingsViewModel.mediaAndFiles.dragAndDropTargetColorStyle
            )
        )
    }
}
