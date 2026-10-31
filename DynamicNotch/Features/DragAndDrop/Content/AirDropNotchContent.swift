//
//  AirDropNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/24/26.
//

import SwiftUI

enum AirDropEvent: Equatable {
    case dragStarted
    case dragEnded
    case dropped
}

struct AirDropNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.DragAndDrop.airDrop.id
    
    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel

    var priority: Int { NotchContentRegistry.DragAndDrop.airDrop.priority }

    var strokeColor: Color {
        DragAndDropTarget.airDrop.activityStrokeColor
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
            AirDropNotchView(
                airDropViewModel: airDropViewModel
            )
        )
    }
}
