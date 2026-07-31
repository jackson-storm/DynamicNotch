import Dispatch
import Foundation
import OSLog

/// Watches the inbox directory for `*.json` drops, parses each into a `NotificationPayload`,
/// hands it off via `onPayload`, then removes the file. Malformed drops are retried once
/// (guarding against non-atomic writers) and, if still unparseable, quarantined in
/// `rejected/`. The inbox directory and the retry delay are injected for testability.
final class NotificationInboxMonitor: NotificationInboxMonitoring {
    var onPayload: ((NotificationPayload) -> Void)?
    var onDrainCompleted: (() -> Void)?

    private let inboxDirectory: URL
    private let retryDelay: TimeInterval
    private let fileManager: FileManager
    private let queue = DispatchQueue(
        label: "com.dynamicnotch.notifications.inbox",
        qos: .utility
    )
    private let logger = Logger(subsystem: "com.dynamicnotch", category: "NotificationInbox")

    private var directorySource: DispatchSourceFileSystemObject?
    private var isMonitoring = false
    private var processingPaths: Set<String> = []

    init(
        inboxDirectory: URL,
        retryDelay: TimeInterval = 0.2,
        fileManager: FileManager = .default
    ) {
        self.inboxDirectory = inboxDirectory
        self.retryDelay = retryDelay
        self.fileManager = fileManager
    }

    deinit {
        directorySource?.cancel()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        queue.async { [weak self] in
            guard let self else { return }
            self.ensureInboxExists()
            // Arm the watcher *before* draining so a drop that lands during startup is either
            // seen by the drain scan or latched by the (already resumed) source — never missed.
            self.installDirectoryWatcher()
            self.scanInbox()
            // Signal drain completion on the main thread. Because each payload from scanInbox()
            // is also dispatched via DispatchQueue.main.async, FIFO ordering on the main queue
            // guarantees this fires AFTER all drain items have been added to the VM.
            DispatchQueue.main.async { [weak self] in self?.onDrainCompleted?() }
        }
    }

    func stopMonitoring() {
        guard isMonitoring || directorySource != nil else { return }
        isMonitoring = false

        directorySource?.cancel()
        directorySource = nil

        queue.async { [weak self] in
            self?.processingPaths.removeAll()
        }
    }
}

private extension NotificationInboxMonitor {
    var rejectedDirectory: URL {
        inboxDirectory.appendingPathComponent("rejected", isDirectory: true)
    }

    func ensureInboxExists() {
        try? fileManager.createDirectory(
            at: inboxDirectory,
            withIntermediateDirectories: true
        )
    }

    func installDirectoryWatcher() {
        guard directorySource == nil else { return }

        let descriptor = open(inboxDirectory.path, O_EVTONLY)
        guard descriptor != -1 else {
            logger.debug("Inbox directory is not available for watching")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.scanInbox()
        }
        source.setCancelHandler {
            close(descriptor)
        }

        directorySource = source
        source.resume()
    }

    func scanInbox() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: inboxDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for url in urls where isEligible(url) {
            process(url)
        }
    }

    func isEligible(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "json" && !url.lastPathComponent.hasPrefix(".")
    }

    func process(_ url: URL) {
        let path = url.standardizedFileURL.path
        guard processingPaths.insert(path).inserted else { return }

        if let payload = parsePayload(at: url) {
            ingest(payload, from: url)
            processingPaths.remove(path)
        } else {
            // Retry once after a short delay: a non-atomic writer may still be mid-write.
            queue.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                guard let self else { return }

                if let payload = self.parsePayload(at: url) {
                    self.ingest(payload, from: url)
                } else {
                    self.reject(url)
                }
                self.processingPaths.remove(path)
            }
        }
    }

    func parsePayload(at url: URL) -> NotificationPayload? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(NotificationPayload.self, from: data)
    }

    func ingest(_ payload: NotificationPayload, from url: URL) {
        // Push to the VM, then remove the file (spec order). NOTE: this is not yet
        // at-least-once — `onPayload` hops to the main actor and persists asynchronously,
        // so a crash before that persist still loses the drop even though we delete last.
        // Deleting only after persistence is confirmed is a deliberate follow-up (see
        // PRD §34), out of scope for this slice.
        onPayload?(payload)
        try? fileManager.removeItem(at: url)
    }

    func reject(_ url: URL) {
        try? fileManager.createDirectory(
            at: rejectedDirectory,
            withIntermediateDirectories: true
        )

        var destination = rejectedDirectory.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: destination.path) {
            destination = rejectedDirectory.appendingPathComponent(
                "\(UUID().uuidString)-\(url.lastPathComponent)"
            )
        }

        do {
            try fileManager.moveItem(at: url, to: destination)
            logger.error("Quarantined malformed inbox file: \(url.lastPathComponent, privacy: .public)")
        } catch {
            // If the move fails (e.g. the file vanished), drop it rather than crash.
            try? fileManager.removeItem(at: url)
        }
    }
}
