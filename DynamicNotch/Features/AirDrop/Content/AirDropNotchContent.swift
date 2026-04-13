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

struct AirDropNotchContent: NotchContentProtocol {
    let id = "airdrop"
    let airDropViewModel: AirDropNotchViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 90 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isAirDropDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        Color.accentColor.opacity(0.3)
    }
    var offsetXTransition: CGFloat { -20 }
    var offsetYTransition: CGFloat { -90 }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 40, height: baseHeight + 110)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(AirDropNotchView(airDropViewModel: airDropViewModel))
    }
}
