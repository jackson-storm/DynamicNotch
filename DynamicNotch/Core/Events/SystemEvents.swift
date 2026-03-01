//
//  SystemEvents.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import Foundation

enum PowerEvent {
    case charger
    case lowPower
    case fullPower
}

enum NetworkEvent {
    case wifiConnected
    case vpnConnected
    case hotspotActive
    case hotspotHide
}

enum HudEvent {
    case display(Int)
    case keyboard(Int)
    case volume(Int)
}

enum FocusEvent {
    case on
    case off
}

enum BluetoothEvent {
    case connected
}

enum OnboardingEvent {
    case onboarding
}
