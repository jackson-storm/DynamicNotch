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

struct TrayNotchContent: NotchContentProtocol {
    let id = NotchContentRegistry.DragAndDrop.tray.id

    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.DragAndDrop.tray.priority }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight + 110)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(TrayNotchView(airDropViewModel: airDropViewModel))
    }
}
