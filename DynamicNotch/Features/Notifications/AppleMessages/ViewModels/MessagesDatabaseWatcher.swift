import Foundation
import Darwin
import OSLog

extension Notification.Name {
    static let messagesDatabaseDidReceiveMessage = Notification.Name("messagesDatabaseDidReceiveMessage")
}

final class MessagesDatabaseWatcher {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesDatabaseWatcher")

    private let reader: MessagesDatabaseReader
    private let queue = DispatchQueue(label: "com.dynamicnotch.messages-database-watcher")

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var lastRowID: Int64 = 0
    private var debounceWorkItem: DispatchWorkItem?

    init(reader: MessagesDatabaseReader) {
        self.reader = reader
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        queue.async { [weak self] in
            guard let self, source == nil else { return }

            guard let latestRowID = reader.latestRowID() else {
                logger.error("Could not read latest Messages RowID")
                return
            }

            lastRowID = latestRowID
            startWatchingWriteAheadLog()
        }
    }

    func stopMonitoring() {
        queue.async { [weak self] in
            guard let self else { return }

            debounceWorkItem?.cancel()
            debounceWorkItem = nil

            source?.cancel()
            source = nil
        }
    }

    private func startWatchingWriteAheadLog() {
        guard let databaseURL = reader.databaseURL() else {
            logger.error("Messages database was not found")
            return
        }
        let writeAheadLogURL = URL(fileURLWithPath: databaseURL.path + "-wal")
        fileDescriptor = open(writeAheadLogURL.path, O_EVTONLY)

        guard fileDescriptor >= 0 else {
            logger.error("Could not open Messages database WAL file")
            scheduleRestart()
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )

        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else { return }

            let event = source.data

            if event.contains(.rename) || event.contains(.delete) {
                restartMonitoring()
                return
            }

            scheduleDatabaseRead()
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }

            let descriptor = self.fileDescriptor

            if descriptor >= 0 {
                close(descriptor)
                self.fileDescriptor = -1
            }
        }

        self.source = source
        source.resume()

        logger.info("Started watching Messages database WAL file")
    }

    private func scheduleDatabaseRead() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.readNewMessages()
        }

        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func readNewMessages() {
        let messages = reader.messages(after: lastRowID)

        guard !messages.isEmpty else { return }

        lastRowID = messages.map(\.rowID).max() ?? lastRowID

        for message in messages {
            post(message)
        }
    }

    private func restartMonitoring() {
        source?.cancel()
        source = nil

        scheduleRestart()
    }

    private func scheduleRestart() {
        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, source == nil else { return }

            startWatchingWriteAheadLog()
        }
    }

    private func post(_ message: MessagesMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .messagesDatabaseDidReceiveMessage,
                object: message
            )
        }
    }
}
