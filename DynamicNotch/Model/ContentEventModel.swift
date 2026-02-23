//
//  EventModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

enum PowerEvent {
    case charger
    case lowPower
    case fullPower
}

enum BluetoothEvent {
    case connected
}

enum OnboardingEvent {
    case onboarding
}

enum VpnEvent {
    case connected
    case disconnected
}

enum HudEvent {
    case volume
    case display
    case keyboard
}
