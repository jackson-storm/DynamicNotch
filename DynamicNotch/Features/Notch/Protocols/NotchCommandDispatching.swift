//
//  NotchCommandDispatching.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import Foundation

@MainActor
protocol NotchCommandDispatching: AnyObject {
    func send(_ notchState: NotchState)
    func setPreferredLiveActivity(id: String?)
    func hideTemporaryNotification()
    func dismissActiveContent()
    func restoreDismissedContent()
    func openActiveWindowLink()
}
