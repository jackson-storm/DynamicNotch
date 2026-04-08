internal import AppKit

final class GlobalClickMonitor {
    private var monitor: Any?

    func start(handler: @escaping (NSEvent) -> Void) {
        stop()
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { event in
            handler(event)
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        self.monitor = nil
    }

    deinit { stop() }
}
