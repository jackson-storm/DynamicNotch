import Foundation

@MainActor
protocol ScreenRecordingMonitoring: AnyObject {
    var onRecordingStateChange: ((Bool) -> Void)? { get set }
    var formattedDuration: String { get }

    func startMonitoring()
    func stopMonitoring()
    func stopRecording()
}

