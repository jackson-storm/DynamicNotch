import Foundation
internal import AppKit

@_silgen_name("CGSIsScreenWatcherPresent")
private func CGSIsScreenWatcherPresent() -> Bool

@_silgen_name("CGSRegisterNotifyProc")
private func CGSRegisterNotifyProc(
    _ callback: (@convention(c) (Int32, Int32, Int32, UnsafeMutableRawPointer?) -> Void)?,
    _ event: Int32,
    _ context: UnsafeMutableRawPointer?
) -> Bool

private func screenRecordingEventCallback(
    _ eventType: Int32,
    _ _: Int32,
    _ _: Int32,
    _ context: UnsafeMutableRawPointer?
) {
    guard let context else { return }

    let monitor = Unmanaged<SystemScreenRecordingMonitor>
        .fromOpaque(context)
        .takeUnretainedValue()

    Task { @MainActor in
        monitor.handleScreenCaptureEvent(eventType)
    }
}

@MainActor
final class SystemScreenRecordingMonitor: NSObject, ScreenRecordingMonitoring {
    var onRecordingStateChange: ((Bool) -> Void)?

    private(set) var isRecording = false
    private(set) var isMonitoring = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var isRecorderIdle = true
    private(set) var lastUpdated: Date = .distantPast

    private let idleDelay: TimeInterval
    private var recordingStartTime: Date?
    private var durationTimer: Timer?
    private var debounceIdleTask: Task<Void, Never>?
    private var hasRegisteredPrivateNotifications = false

    init(idleDelay: TimeInterval = 3) {
        self.idleDelay = idleDelay
    }

    deinit {
        debounceIdleTask?.cancel()
        durationTimer?.invalidate()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        setupPrivateAPINotifications()
        checkRecordingStatus()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        stopDurationTracking()
        debounceIdleTask?.cancel()
        isRecorderIdle = true
        applyRecordingState(false)
    }
}

extension SystemScreenRecordingMonitor {
    var currentRecordingStatus: Bool {
        isRecording
    }

    var isMonitoringAvailable: Bool {
        true
    }

    var formattedDuration: String {
        let totalSeconds = Int(recordingDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(format: "%d:%02d", minutes, seconds)
    }
}

private extension SystemScreenRecordingMonitor {
    func setupPrivateAPINotifications() {
        guard !hasRegisteredPrivateNotifications else { return }

        let context = Unmanaged.passUnretained(self).toOpaque()
        let registeredConnect = CGSRegisterNotifyProc({ eventType, value1, value2, context in
            screenRecordingEventCallback(eventType, value1, value2, context)
        }, 1502, context)
        let registeredDisconnect = CGSRegisterNotifyProc({ eventType, value1, value2, context in
            screenRecordingEventCallback(eventType, value1, value2, context)
        }, 1503, context)

        hasRegisteredPrivateNotifications = registeredConnect || registeredDisconnect
    }

    func handleScreenCaptureEvent(_ eventType: Int32) {
        guard isMonitoring else { return }
        checkRecordingStatus()
    }

    func checkRecordingStatus() {
        guard isMonitoring else { return }

        let currentRecordingState = CGSIsScreenWatcherPresent()
        guard currentRecordingState != isRecording else { return }

        lastUpdated = Date()

        if currentRecordingState {
            startDurationTracking()
            updateIdleState(recording: true)
        } else {
            stopDurationTracking()
            updateIdleState(recording: false)
        }

        applyRecordingState(currentRecordingState)
    }

    func applyRecordingState(_ nextIsRecording: Bool) {
        guard isRecording != nextIsRecording else { return }

        isRecording = nextIsRecording
        onRecordingStateChange?(nextIsRecording)
    }

    func startDurationTracking() {
        recordingStartTime = Date()
        recordingDuration = 0
        durationTimer?.invalidate()

        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateDuration()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        durationTimer = timer
    }

    func stopDurationTracking() {
        durationTimer?.invalidate()
        durationTimer = nil
        recordingStartTime = nil

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.recordingDuration = 0
        }
    }

    func updateDuration() {
        guard let recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(recordingStartTime)
    }

    func updateIdleState(recording: Bool) {
        if recording {
            isRecorderIdle = false
            debounceIdleTask?.cancel()
            return
        }

        debounceIdleTask?.cancel()
        debounceIdleTask = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(self.idleDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            if self.lastUpdated.timeIntervalSinceNow < -self.idleDelay {
                self.isRecorderIdle = !self.isRecording
            }
        }
    }
}
