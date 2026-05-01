import Combine
import Foundation

@MainActor
final class ScreenRecordingViewModel: ObservableObject {
    @Published private(set) var isRecording = false
    @Published var event: ScreenRecordingEvent?

    private let monitor: any ScreenRecordingMonitoring
    private var hasStartedMonitoring = false
    private var ignoresMonitorState = false

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

        case (true, false):
            event = .stopped

        default:
            break
        }
    }
}
