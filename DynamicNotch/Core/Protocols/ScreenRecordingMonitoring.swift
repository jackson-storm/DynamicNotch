import Foundation

@MainActor
protocol ScreenRecordingMonitoring: AnyObject {
    var onRecordingStateChange: ((Bool) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
