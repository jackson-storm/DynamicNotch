import Darwin
import Foundation
import OSLog

extension Notification.Name {
    static let messagesDatabaseDidReceiveMessage = Notification.Name("messagesDatabaseDidReceiveMessage")
}

final class MessagesDatabaseWatcher {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesDatabaseWatcher")

    private let reader: MessagesDatabaseReader
    private let queue = DispatchQueue(label: "com.dynamicnotch.messages-database-watcher", qos: .utility)

    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var isMonitoring = false
    private var lastRowID: Int64 = 0
    private var monitoringStartedAt = Date.distantPast
    private var monitoringGeneration = UUID()

    private let debounceDelay: TimeInterval = 0.25
    private let refreshDelay: TimeInterval = 0.5
    private let maximumRefreshAttempts = 10

    init(reader: MessagesDatabaseReader) {
        self.reader = reader
    }

    deinit {
        debounceWorkItem?.cancel()
        source?.cancel()
    }

    func startMonitoring() {
        queue.async { [weak self] in
            guard let self, !isMonitoring else { return }

            guard let latestRowID = reader.latestRowID() else {
                logger.error("Could not initialize Messages RowID checkpoint")
                return
            }

            lastRowID = latestRowID
            monitoringStartedAt = Date()
            monitoringGeneration = UUID()
            isMonitoring = true

            startWatchingWriteAheadLog()

            logger.info("Started monitoring Messages database")
        }
    }

    func stopMonitoring() {
        queue.async { [weak self] in
            guard let self, isMonitoring else { return }

            isMonitoring = false
            monitoringStartedAt = .distantPast
            monitoringGeneration = UUID()

            debounceWorkItem?.cancel()
            debounceWorkItem = nil

            source?.cancel()
            source = nil

            logger.info("Stopped monitoring Messages database")
        }
    }

    private func startWatchingWriteAheadLog() {
        guard isMonitoring, source == nil else { return }

        guard let databaseURL = reader.databaseURL() else {
            logger.error("Messages database was not found")
            return
        }

        let walURL = URL(fileURLWithPath: databaseURL.path + "-wal")
        let descriptor = open(walURL.path, O_EVTONLY)

        guard descriptor >= 0 else {
            scheduleWatcherRestart()
            return
        }

        let newSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: [.write, .extend, .rename, .delete], queue: queue)

        newSource.setEventHandler { [weak self, weak newSource] in
            guard let self, let newSource, isMonitoring else { return }

            let event = newSource.data

            if event.contains(.rename) || event.contains(.delete) {
                restartWatcher()
                return
            }

            scheduleDatabaseRead()
        }

        newSource.setCancelHandler {
            close(descriptor)
        }

        source = newSource
        newSource.resume()

        readNewMessages()
    }

    private func restartWatcher() {
        source?.cancel()
        source = nil

        scheduleWatcherRestart()
    }

    private func scheduleWatcherRestart() {
        let generation = monitoringGeneration

        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, isMonitoring, monitoringGeneration == generation, source == nil else { return }

            startWatchingWriteAheadLog()
        }
    }

    private func scheduleDatabaseRead() {
        debounceWorkItem?.cancel()

        let generation = monitoringGeneration
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, isMonitoring, monitoringGeneration == generation else { return }

            readNewMessages()
        }

        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }

    private func readNewMessages() {
        guard isMonitoring else { return }

        guard let latestRowID = reader.latestRowID(), latestRowID > lastRowID else { return }

        guard let messages = reader.messages(after: lastRowID) else {
            logger.error("Could not read new Messages rows")
            return
        }

        let highestMessageRowID = messages.map(\.rowID).max() ?? lastRowID
        lastRowID = max(latestRowID, highestMessageRowID)

        for message in messages {
            guard message.receivedDate >= monitoringStartedAt else {
                logger.debug("Ignoring Messages row received before monitoring started")
                continue
            }

            if isReadyForPresentation(message) {
                post(message)
            } else {
                scheduleMessageRefresh(rowID: message.rowID, attempt: 1)
            }
        }
    }

    private func scheduleMessageRefresh(rowID: Int64, attempt: Int) {
        let generation = monitoringGeneration

        queue.asyncAfter(deadline: .now() + refreshDelay) { [weak self] in
            guard let self, isMonitoring, monitoringGeneration == generation else { return }

            refreshMessage(rowID: rowID, attempt: attempt)
        }
    }

    private func refreshMessage(rowID: Int64, attempt: Int) {
        guard let message = reader.message(withRowID: rowID) else {
            if attempt < maximumRefreshAttempts {
                scheduleMessageRefresh(rowID: rowID, attempt: attempt + 1)
            } else {
                logger.info("Ignoring unavailable Messages row \(rowID)")
            }

            return
        }

        if isReadyForPresentation(message) {
            post(message)
            return
        }

        if attempt < maximumRefreshAttempts {
            scheduleMessageRefresh(rowID: rowID, attempt: attempt + 1)
            return
        }

        if !message.parts.isEmpty {
            post(message)
        } else {
            logger.info("Ignoring incomplete Messages row \(rowID)")
        }
    }

    private func isReadyForPresentation(_ message: MessagesMessage) -> Bool {
        guard !message.parts.isEmpty else { return false }

        return message.parts.allSatisfy { part in
            switch part {
            case .text:
                return true
            case .attachment(let attachment):
                return attachmentIsAvailable(attachment)
            }
        }
    }

    private func attachmentIsAvailable(_ attachment: MessagesAttachment) -> Bool {
        switch attachment {
        case .image(let attachment):
            return attachment.fileURL != nil
        case .video(let attachment):
            return attachment.fileURL != nil
        case .audio(let attachment):
            return attachment.fileURL != nil
        case .file(let attachment):
            return attachment.fileURL != nil
        }
    }

    private func post(_ message: MessagesMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .messagesDatabaseDidReceiveMessage, object: message)
        }
    }
}
