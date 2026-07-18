//
//  NotchSizeHeightNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/31/26.
//

import SwiftUI

struct NotchSizeHeightNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.NotchSize.height.id
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.NotchSize.height.priority }
    var strokeColor: Color { .red }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 70, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(NotchSizeHeightNotchView(settingsViewModel: settingsViewModel))
    }
}
