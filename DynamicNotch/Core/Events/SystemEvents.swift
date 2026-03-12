//
//  SystemEvents.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import Foundation

enum PowerEvent: Equatable {
    case charger
    case lowPower
    case fullPower
}

enum NetworkEvent: Equatable {
    case wifiConnected
    case vpnConnected
    case hotspotActive
    case hotspotHide
}

enum HudEvent: Equatable {
    case display(Int)
    case keyboard(Int)
    case volume(Int)
}

enum AirDropEvent: Equatable {
    case dragStarted
    case dragEnded
    case dropped(urls: [URL], point: NSPoint)
}

enum FocusEvent: Equatable {
    case FocusOn
    case FocusOff
}

enum NotchSizeEvent: Equatable {
    case width
    case height
}

enum BluetoothEvent: Equatable {
    case connected
}

enum OnboardingEvent: Equatable {
    case onboarding
}
