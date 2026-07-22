import Combine
import Foundation

@MainActor
final class ScreenRecordingViewModel: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var formattedDuration: String = "00:00"
    @Published var event: ScreenRecordingEvent?

    private let monitor: any ScreenRecordingMonitoring
    private var hasStartedMonitoring = false
    private var ignoresMonitorState = false
    private var durationTimer: Timer?

    init(monitor: any ScreenRecordingMonitoring) {
        self.monitor = monitor
        self.monitor.onRecordingStateChange = { [weak self] isRecording in
            self?.handleMonitorState(isRecording)
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }

        hasStartedMonitoring = true
        ignoresMonitorState = false
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }

        hasStartedMonitoring = false
        ignoresMonitorState = true
        monitor.stopMonitoring()
        commit(false)
    }

    func stopRecording() {
        monitor.stopRecording()
    }
}

private extension ScreenRecordingViewModel {
    func handleMonitorState(_ nextIsRecording: Bool) {
        guard !ignoresMonitorState else { return }
        commit(nextIsRecording)
    }

    func commit(_ nextIsRecording: Bool) {
        let wasRecording = isRecording
        isRecording = nextIsRecording

        switch (wasRecording, nextIsRecording) {
        case (false, true):
            event = .started
            startTimer()

        case (true, false):
            event = .stopped
            stopTimer()

        default:
            break
        }
    }

    func startTimer() {
        durationTimer?.invalidate()
        updateFormattedDuration()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateFormattedDuration()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        durationTimer = timer
    }

    func stopTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        formattedDuration = "00:00"
    }

    func updateFormattedDuration() {
        formattedDuration = monitor.formattedDuration
    }
}
