//
//  InactiveAudioOutputRoutingService.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/8/26.
//

import CoreAudio

final class InactiveAudioOutputRoutingService: AudioOutputRouting {
    func availableRoutes() -> [AudioOutputRoute] { [] }

    func currentRoute() -> AudioOutputRoute? { nil }

    @discardableResult
    func setCurrentRoute(_ id: AudioDeviceID) -> Bool { false }
}
