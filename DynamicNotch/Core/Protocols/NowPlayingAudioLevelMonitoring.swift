//
//  NowPlayingAudioLevelMonitoring.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

protocol NowPlayingAudioLevelMonitoring: AnyObject {
    var onLevelsChange: (([CGFloat]) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
