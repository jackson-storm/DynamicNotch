import Foundation

@MainActor
final class InactiveScreenRecordingMonitor: ScreenRecordingMonitoring {
    var onRecordingStateChange: ((Bool) -> Void)?
    var formattedDuration: String { "00:01" }

    func startMonitoring() {
        onRecordingStateChange?(false)
    }

    func stopMonitoring() {}
    func stopRecording() {}
}

