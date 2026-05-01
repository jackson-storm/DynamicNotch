import Foundation

@MainActor
final class InactiveScreenRecordingMonitor: ScreenRecordingMonitoring {
    var onRecordingStateChange: ((Bool) -> Void)?

    func startMonitoring() {
        onRecordingStateChange?(false)
    }

    func stopMonitoring() {}
}
