import Foundation
internal import AppKit

final class MessagesManager {

    var onMessageReceived: ((MessagesMessage) -> Void)?

    private let reader: MessagesDatabaseReader
    private let watcher: MessagesDatabaseWatcher
    private var observer: NSObjectProtocol?

    init(reader: MessagesDatabaseReader = MessagesDatabaseReader()) {
        self.reader = reader
        self.watcher = MessagesDatabaseWatcher(reader: reader)
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: .messagesDatabaseDidReceiveMessage,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let message = notification.object as? MessagesMessage else { return }
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

    func open(_ message: MessagesMessage) {
        // Try opening specific conversation or handle
        if !message.senderHandle.isEmpty {
            let sanitizedHandle = message.senderHandle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? message.senderHandle
            if let url = URL(string: "imessage://\(sanitizedHandle)"), NSWorkspace.shared.open(url) {
                return
            }
            if let url = URL(string: "messages://\(sanitizedHandle)"), NSWorkspace.shared.open(url) {
                return
            }
        }

        // Fallback to opening Messages application
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") ??
                        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iChat") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
        }
    }
}
