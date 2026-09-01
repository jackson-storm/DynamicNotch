import CoreAudio
import Foundation

/// Watches CoreAudio for volume, mute and output-device changes that do **not**
/// travel through the keyboard media keys — headphone stem gestures, Control
/// Center, Siri, or plugging/unplugging a device. The media-key event tap can
/// only see key presses, so those sources were previously invisible to the app
/// while macOS still drew its own OSD. This observer fills that gap and lets the
/// notch HUD react to them too.
///
/// Callbacks are always delivered on the main queue.
final class SystemAudioChangeObserver {
    /// Emitted when the volume/mute of the current output device changes from an
    /// external source. `level` is 0…100.
    var onVolumeChange: ((_ level: Int, _ deviceName: String?) -> Void)?

    private let audioService: SystemAudioVolumeService

    /// Elements we register volume/mute listeners on. Mirrors the candidates the
    /// volume service writes to so we observe whichever channel the device uses.
    private let candidateElements: [AudioObjectPropertyElement] = [
        kAudioObjectPropertyElementMain,
        AudioObjectPropertyElement(1),
        AudioObjectPropertyElement(2)
    ]

    private var isObserving = false
    private var observedDeviceID: AudioDeviceID = 0
    private var lastReportedLevel: Int = -1
    private var lastDefaultDeviceChangeAt: Date = .distantPast

    /// Changes within this window of one of our own writes are treated as echoes
    /// of the media-key path and ignored, so we don't show the HUD twice.
    private let programmaticEchoWindow: TimeInterval = 0.3
    private let deviceChangeIgnoreWindow: TimeInterval = 1.0

    private lazy var listenerBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        // CoreAudio may deliver on an arbitrary queue; the block itself is bound
        // to the main queue below, but guard anyway.
        self?.handleDeviceLevelChange()
    }

    private lazy var deviceChangeBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.handleDefaultDeviceChange()
    }

    init(audioService: SystemAudioVolumeService) {
        self.audioService = audioService
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            deviceChangeBlock
        )

        registerDeviceListeners(for: audioService.currentOutputDeviceID)
        lastReportedLevel = currentLevel()
    }

    func stopObserving() {
        guard isObserving else { return }
        isObserving = false

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            deviceChangeBlock
        )

        unregisterDeviceListeners()
    }

    // MARK: - Device listener management

    private func registerDeviceListeners(for deviceID: AudioDeviceID) {
        guard deviceID != 0 else { return }
        observedDeviceID = deviceID

        for selector in [kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
            for element in candidateElements {
                var address = AudioObjectPropertyAddress(
                    mSelector: selector,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: element
                )
                guard AudioObjectHasProperty(deviceID, &address) else { continue }
                AudioObjectAddPropertyListenerBlock(
                    deviceID,
                    &address,
                    DispatchQueue.main,
                    listenerBlock
                )
            }
        }
    }

    private func unregisterDeviceListeners() {
        guard observedDeviceID != 0 else { return }

        for selector in [kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
            for element in candidateElements {
                var address = AudioObjectPropertyAddress(
                    mSelector: selector,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: element
                )
                guard AudioObjectHasProperty(observedDeviceID, &address) else { continue }
                AudioObjectRemovePropertyListenerBlock(
                    observedDeviceID,
                    &address,
                    DispatchQueue.main,
                    listenerBlock
                )
            }
        }

        observedDeviceID = 0
    }

    // MARK: - Change handling

    private func handleDefaultDeviceChange() {
        guard isObserving else { return }

        lastDefaultDeviceChangeAt = Date()

        unregisterDeviceListeners()
        let newDeviceID = audioService.currentOutputDeviceID
        registerDeviceListeners(for: newDeviceID)

        let level = currentLevel()
        lastReportedLevel = level
    }

    private func handleDeviceLevelChange() {
        guard isObserving else { return }

        if Date().timeIntervalSince(lastDefaultDeviceChangeAt) < deviceChangeIgnoreWindow {
            // Ignore volume changes immediately after switching output devices
            lastReportedLevel = currentLevel()
            return
        }

        if Date().timeIntervalSince(audioService.lastProgrammaticChangeAt) < programmaticEchoWindow {
            // We just wrote this value from the media-key path; the HUD is already
            // being shown by HardwareHUDMonitor. Keep our baseline in sync but
            // stay silent.
            lastReportedLevel = currentLevel()
            return
        }

        let level = currentLevel()
        guard level != lastReportedLevel else { return }
        lastReportedLevel = level

        onVolumeChange?(level, audioService.currentDeviceName)
    }

    private func currentLevel() -> Int {
        Int((audioService.currentEffectiveVolume * 100).rounded())
    }
}
