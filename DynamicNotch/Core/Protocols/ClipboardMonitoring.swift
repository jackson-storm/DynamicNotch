import Foundation

@MainActor
protocol ClipboardMonitoring: AnyObject {
    var onClipboardChange: ((ClipboardSnapshot) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
    func write(_ payload: ClipboardPayload) -> Bool
}

@MainActor
final class InactiveClipboardMonitor: ClipboardMonitoring {
    var onClipboardChange: ((ClipboardSnapshot) -> Void)?

    func startMonitoring() {}
    func stopMonitoring() {}
    func write(_ payload: ClipboardPayload) -> Bool { false }
}
