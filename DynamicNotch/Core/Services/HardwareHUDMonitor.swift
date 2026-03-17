import AppKit
import Foundation

@MainActor
final class HardwareHUDMonitor {
    var onEvent: ((HudEvent) -> Void)?

    private let mediaKeyTap: SystemMediaKeyTap
    private let audioService: SystemAudioVolumeService
    private let brightnessService: SystemDisplayBrightnessService

    private(set) var isMonitoring = false

    init(
        mediaKeyTap: SystemMediaKeyTap = SystemMediaKeyTap(),
        audioService: SystemAudioVolumeService = SystemAudioVolumeService(),
        brightnessService: SystemDisplayBrightnessService = SystemDisplayBrightnessService()
    ) {
        self.mediaKeyTap = mediaKeyTap
        self.audioService = audioService
        self.brightnessService = brightnessService
    }

    func updateConfiguration(
        interceptVolume: Bool,
        interceptBrightness: Bool
    ) {
        mediaKeyTap.configuration = SystemMediaKeyTapConfiguration(
            interceptVolume: interceptVolume,
            interceptBrightness: interceptBrightness
        )
    }

    func startMonitoring() {
        guard !isMonitoring else {
            return
        }

        mediaKeyTap.delegate = self
        isMonitoring = mediaKeyTap.start()
    }

    func stopMonitoring() {
        mediaKeyTap.stop()
        mediaKeyTap.delegate = nil
        isMonitoring = false
    }

    private func emit(_ event: HudEvent) {
        onEvent?(event)
    }
}

extension HardwareHUDMonitor: SystemMediaKeyTapDelegate {
    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveVolumeCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    ) {
        let level = audioService.adjust(direction: direction, granularity: granularity)
        emit(.volume(level))
    }

    func mediaKeyTapDidToggleMute(_ tap: SystemMediaKeyTap) {
        let level = audioService.toggleMute()
        emit(.volume(level))
    }

    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveBrightnessCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    ) {
        let level = brightnessService.adjust(direction: direction, granularity: granularity)
        emit(.display(level))
    }
}
