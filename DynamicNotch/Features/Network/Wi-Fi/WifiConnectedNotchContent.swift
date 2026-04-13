//
//  WifiConnectedNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/26/26.
//

import SwiftUI

struct WifiConnectedNotchContent: NotchContentProtocol {
    let id = "wifi.connected"
    let networkViewModel: NetworkViewModel
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            WifiConnectedNotchView(
                networkViewModel: networkViewModel
            )
        )
    }
}
