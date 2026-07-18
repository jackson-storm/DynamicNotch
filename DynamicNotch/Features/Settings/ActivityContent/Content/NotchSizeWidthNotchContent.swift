//
//  NotchSizeNotch.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/10/26.
//

import SwiftUI

enum NotchSizeEvent: Equatable {
    case width
    case height
}

struct NotchSizeWidthNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.NotchSize.width.id
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.NotchSize.width.priority }
    var strokeColor: Color { .red }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight + 40)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 20, height: baseHeight + 40)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeWidthNotchView(settingsViewModel: settingsViewModel))
    }
}
