//
//  EventModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation

enum NotchEvent {
    case showLiveActivitiy(NotchContent)
    case showTemporaryNotification(NotchContent, duration: TimeInterval)
    case hide
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

enum VpnEvent {
    case connected
    case disconnected
}

enum HudEvent {
    case volume
    case display
    case keyboard
}

enum ExpandedEvent {
    case none
    case expanded
}
