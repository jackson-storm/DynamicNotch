import Foundation
import Darwin
import OSLog

extension Notification.Name {
    //Posted when a new Mail message is available
    static let mailDatabaseDidReceiveMessage = Notification.Name("mailDatabaseDidReceiveMessage")
}

final class MailDatabaseWatcher {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MailDatabaseWatcher")

    private let reader: MailDatabaseReader
    private let queue = DispatchQueue(label: "com.dynamicnotch.mail-database-watcher")

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var lastRowID: Int64 = 0
    private var debounceWorkItem: DispatchWorkItem?

    init(reader: MailDatabaseReader) {
        self.reader = reader
    }

    deinit {
        stopMonitoring()
    }
    
    //Store the latest RowID and start watching Mail database
    func startMonitoring() {
        queue.async { [weak self] in
            guard let self, source == nil else { return }

            guard let latestRowID = reader.latestRowID() else {
                logger.error("Could not read latest Mail RowID")
                return
            }

            lastRowID = latestRowID
            startWatchingWriteAheadLog()
        }
    }
    
    //Stop watching Mail database and cancel any pending database read
    func stopMonitoring() {
        queue.async { [weak self] in
            guard let self else { return }

            debounceWorkItem?.cancel()
            debounceWorkItem = nil

            source?.cancel()
            source = nil
        }
    }
    
    //Start monitoring changes to Mail database WAL file
    private func startWatchingWriteAheadLog() {
        guard let databaseURL = reader.databaseURL() else {
            logger.error("Mail database was not found")
            return
        }

        //Add -wal because Mail writes changes here
        let writeAheadLogURL = URL(fileURLWithPath: databaseURL.path + "-wal")
        //Open file without read permission
        fileDescriptor = open(writeAheadLogURL.path, O_EVTONLY)

        guard fileDescriptor >= 0 else {
            logger.error("Could not open Mail database WAL file")
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

        logger.info("Started watching Mail database WAL file")
    }
    
    //Delay database read to merge multiple WAL events into one operation
    private func scheduleDatabaseRead() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.readNewMessages()
        }

        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }
    
    //Read all messages added after the last processed RowID
    private func readNewMessages() {
        let messages = reader.messages(after: lastRowID)

        guard !messages.isEmpty else { return }

        lastRowID = messages.map(\.rowID).max() ?? lastRowID

        for message in messages {
            message.summary?.isEmpty == false ? post(message) : scheduleMessageRefresh(for: message)
        }
    }
    
    //Cancel the current watcher and schedule its recreation
    private func restartMonitoring() {
        source?.cancel()
        source = nil

        scheduleRestart()
    }
    
    //Retry watcher creation after the WAL file becomes available again
    private func scheduleRestart() {
        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, source == nil else { return }

            startWatchingWriteAheadLog()
        }
    }
    
    //Post a new Mail message notification
    private func post(_ message: MailMessage) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .mailDatabaseDidReceiveMessage,
                object: message
            )
        }
    }
    
    //Retry reading a Mail message until its summary is available
    private func scheduleMessageRefresh(
        for message: MailMessage,
        attempt: Int = 1
    ) {
        queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            guard let refreshedMessage = reader.message(withRowID: message.rowID) else {
                post(message)
                return
            }

            if refreshedMessage.summary?.isEmpty == false {
                post(refreshedMessage)
                return
            }

            if attempt >= 10 {
                post(refreshedMessage)
                return
            }

            scheduleMessageRefresh(
                for: refreshedMessage,
                attempt: attempt + 1
            )
        }
    }
}
