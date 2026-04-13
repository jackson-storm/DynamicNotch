//
//  LockScreenMonitoring.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/15/26.
//

import Foundation

protocol LockScreenMonitoring: AnyObject {
    var onLockStateChange: ((Bool) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
