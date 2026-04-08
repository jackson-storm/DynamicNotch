internal import AppKit
import Foundation

@MainActor
final class HardwareHUDMonitor {
    var onEvent: ((HudEvent) -> Void)?

    private let mediaKeyTap: SystemMediaKeyTap
    private let audioService: SystemAudioVolumeService
    private let brightnessService: SystemDisplayBrightnessService
    private var accessibilityRetryTimer: Timer?

    private(set) var isMonitoring = false

    init(
        mediaKeyTap: SystemMediaKeyTap,
        audioService: SystemAudioVolumeService,
        brightnessService: SystemDisplayBrightnessService
    ) {
        self.mediaKeyTap = mediaKeyTap
        self.audioService = audioService
        self.brightnessService = brightnessService
    }

    convenience init() {
        self.init(
            mediaKeyTap: SystemMediaKeyTap(),
            audioService: SystemAudioVolumeService(),
            brightnessService: SystemDisplayBrightnessService()
        )
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

        if isMonitoring {
            stopAccessibilityRetryTimer()
        } else if mediaKeyTap.isAccessibilityTrusted == false {
            scheduleAccessibilityRetry()
        }
    }

    func stopMonitoring() {
        stopAccessibilityRetryTimer()
        mediaKeyTap.stop()
        mediaKeyTap.delegate = nil
        isMonitoring = false
    }

    private func emit(_ event: HudEvent) {
        onEvent?(event)
    }

    private func scheduleAccessibilityRetry() {
        guard accessibilityRetryTimer == nil else {
            return
        }

        let timer = Timer(
            timeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.retryStartMonitoringIfPossible()
            }
        }
        accessibilityRetryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAccessibilityRetryTimer() {
        accessibilityRetryTimer?.invalidate()
        accessibilityRetryTimer = nil
    }

    private func retryStartMonitoringIfPossible() {
        guard !isMonitoring else {
            stopAccessibilityRetryTimer()
            return
        }

        guard mediaKeyTap.isAccessibilityTrusted else {
            return
        }

        isMonitoring = mediaKeyTap.start()
        if isMonitoring {
            stopAccessibilityRetryTimer()
        }
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
