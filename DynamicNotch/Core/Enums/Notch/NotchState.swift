//
//  NotchState.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

import Foundation

enum NotchState {
    case showLiveActivity(NotchContentProtocol)
    case hideLiveActivity(id: String)
    case dismissLiveActivity(id: String)
    case showTemporaryNotification(NotchContentProtocol, duration: TimeInterval)
    case hide
}
