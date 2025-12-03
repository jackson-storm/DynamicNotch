import AppKit

final class GlobalClickMonitor {
    private var monitor: Any?
    func start(handler: @escaping () -> Void) {
        stop()
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { _ in
            handler()
        }
    }
    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        self.monitor = nil
    }
    deinit { stop() }
}
