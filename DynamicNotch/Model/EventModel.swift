//
//  EventModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

enum NotchEvent {
    case showActive(NotchContent)
    case showTemporary(NotchContent, duration: TimeInterval)
    case hideTemporary
}

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

enum NetworkEvent {
    case connected
    case disconnected
}
