//
//  TrayContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/25/26.
//

import SwiftUI

enum TrayEvent {
    case dragStarted
    case dragEnded
    case dropped
}

struct TrayNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.tray.id

    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.DragAndDrop.tray.priority }

    var strokeColor: Color {
        DragAndDropTarget.tray.activityStrokeColor
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 40)
    }
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 80, height: baseHeight + 110)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.22
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(
            TrayNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }
}
