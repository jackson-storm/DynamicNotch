//
//  DragAndDropCombinedNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

struct DragAndDropCombinedNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.DragAndDrop.combined.id

    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel

    var priority: Int { NotchContentRegistry.DragAndDrop.combined.priority }

    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isDragAndDropDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        airDropViewModel.targetedDropTarget == .airDrop ? .accentColor.opacity(0.3) : .white.opacity(0.2)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: max(baseWidth + 220, 420), height: baseHeight + 110)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(DragAndDropCombinedNotchView(airDropViewModel: airDropViewModel))
    }
}
