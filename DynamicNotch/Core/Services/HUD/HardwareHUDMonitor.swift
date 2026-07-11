internal import AppKit
import Foundation

@MainActor
final class HardwareHUDMonitor {
    var onEvent: ((HudEvent) -> Void)?

    private let mediaKeyTap: SystemMediaKeyTap
    private let audioService: SystemAudioVolumeService
    private let brightnessService: SystemDisplayBrightnessService
    private let volumeFeedbackPlayer: VolumeFeedbackSoundPlayer
    private let audioChangeObserver: SystemAudioChangeObserver
    private var accessibilityRetryTimer: Timer?

    private(set) var isMonitoring = false

    /// Whether external (non-media-key) volume changes should be surfaced. Driven
    /// by the same setting as the media-key volume interception.
    private var interceptVolume = false
    private var isObservingAudioChanges = false

    init(
        mediaKeyTap: SystemMediaKeyTap,
        audioService: SystemAudioVolumeService,
        brightnessService: SystemDisplayBrightnessService,
        volumeFeedbackPlayer: VolumeFeedbackSoundPlayer? = nil
    ) {
        self.mediaKeyTap = mediaKeyTap
        self.audioService = audioService
        self.brightnessService = brightnessService
        self.volumeFeedbackPlayer = volumeFeedbackPlayer ?? VolumeFeedbackSoundPlayer()
        self.audioChangeObserver = SystemAudioChangeObserver(audioService: audioService)

        configureAudioChangeObserver()
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
        self.interceptVolume = interceptVolume
        mediaKeyTap.configuration = SystemMediaKeyTapConfiguration(
            interceptVolume: interceptVolume,
            interceptBrightness: interceptBrightness
        )
        updateAudioChangeObservation()
    }

    func startMonitoring() {
        // The CoreAudio observer needs no accessibility permission, so start it
        // regardless of whether the media-key tap succeeds.
        updateAudioChangeObservation()

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
        stopAudioChangeObservation()
    }

    private func emit(_ event: HudEvent) {
        onEvent?(event)
    }

    // MARK: - External audio change observation

    private func configureAudioChangeObserver() {
        audioChangeObserver.onVolumeChange = { [weak self] level, deviceName in
            MainActor.assumeIsolated {
                self?.handleExternalVolumeChange(level: level, deviceName: deviceName)
            }
        }

        audioChangeObserver.onOutputDeviceChange = { [weak self] level, deviceName in
            MainActor.assumeIsolated {
                self?.handleOutputDeviceChange(level: level, deviceName: deviceName)
            }
        }
    }

    private func updateAudioChangeObservation() {
        if interceptVolume {
            startAudioChangeObservation()
        } else {
            stopAudioChangeObservation()
        }
    }

    private func startAudioChangeObservation() {
        guard !isObservingAudioChanges else { return }
        isObservingAudioChanges = true
        audioChangeObserver.startObserving()
    }

    private func stopAudioChangeObservation() {
        guard isObservingAudioChanges else { return }
        isObservingAudioChanges = false
        audioChangeObserver.stopObserving()
    }

    private func handleExternalVolumeChange(level: Int, deviceName: String?) {
        // These changes don't come from a key we can consume (headphone stem,
        // Control Center, Siri), so macOS draws its own OSD and — since it's owned
        // by MenuBarAgent on macOS 26 — it can't be suppressed. We simply mirror
        // the change in our HUD alongside it.
        emit(.volume(level: level, deviceName: deviceName))
    }

    private func handleOutputDeviceChange(level: Int, deviceName: String?) {
        emit(.volume(level: level, deviceName: deviceName))
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
        // The tap consumed the key event, so macOS won't play its own volume tick;
        // reproduce it here to match the stock experience.
        volumeFeedbackPlayer.playIfNeeded(shiftHeld: modifiers.contains(.shift))
        emit(.volume(level: level, deviceName: audioService.currentDeviceName))
    }

    func mediaKeyTapDidToggleMute(_ tap: SystemMediaKeyTap) {
        let level = audioService.toggleMute()
        emit(.volume(level: level, deviceName: audioService.currentDeviceName))
    }

    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveBrightnessCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    ) {
        // The brightness key is consumed (no system OSD), so we set the value
        // ourselves and show our HUD. Steps are discrete — the smooth hardware
        // ramp isn't reachable through the working private setter.
        let level = brightnessService.adjust(direction: direction, granularity: granularity)
        emit(.display(level))
    }
}
