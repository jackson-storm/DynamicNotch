import Foundation
internal import AppKit

final class MailManager {

    var onMessageReceived: ((MailMessage) -> Void)?

    private let reader: MailDatabaseReader
    private let watcher: MailDatabaseWatcher
    private var observer: NSObjectProtocol?

    init(reader: MailDatabaseReader = MailDatabaseReader()) {
        self.reader = reader
        self.watcher = MailDatabaseWatcher(reader: reader)
    }

    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: .mailDatabaseDidReceiveMessage,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            
            guard let self, let message = notification.object as? MailMessage else { return }

            onMessageReceived?(message)
        }

        watcher.startMonitoring()
    }
    
    func stopMonitoring() {
        watcher.stopMonitoring()

        guard let observer else { return }

        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }
    
    func open(_ message: MailMessage) {
        guard !message.messageIDHeader.isEmpty,
              let url = URL(string: "message:\(message.messageIDHeader)") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
