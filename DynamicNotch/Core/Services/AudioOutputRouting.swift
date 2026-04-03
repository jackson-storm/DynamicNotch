import CoreAudio

protocol AudioOutputRouting: AnyObject {
    func availableRoutes() -> [AudioOutputRoute]
    func currentRoute() -> AudioOutputRoute?
    @discardableResult func setCurrentRoute(_ id: AudioDeviceID) -> Bool
}

final class InactiveAudioOutputRoutingService: AudioOutputRouting {
    func availableRoutes() -> [AudioOutputRoute] { [] }

    func currentRoute() -> AudioOutputRoute? { nil }

    @discardableResult
    func setCurrentRoute(_ id: AudioDeviceID) -> Bool { false }
}
