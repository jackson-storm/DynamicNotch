import Foundation
internal import AppKit
import OSLog

final class MessagesManager {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesManager")

    var onMessageReceived: ((MessagesMessage) -> Void)?

    private let watcher: MessagesDatabaseWatcher
    private var observer: NSObjectProtocol?

    init(reader: MessagesDatabaseReader = MessagesDatabaseReader()) {
        watcher = MessagesDatabaseWatcher(reader: reader)
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
            guard let self else { return }

            guard let message = notification.object as? MessagesMessage else {
                logger.error("Received invalid Messages database notification")
                return
            }

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
        guard message.conversation?.isGroup != true else {
            openMessagesApplication()
            return
        }

        guard let url = conversationURL(for: message.sender.identifier) else {
            logger.error("Could not create Messages conversation URL")
            openMessagesApplication()
            return
        }

        guard NSWorkspace.shared.open(url) else {
            logger.error("Could not open Messages conversation")
            openMessagesApplication()
            return
        }
    }

    private func conversationURL(for identifier: String) -> URL? {
        let normalizedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedIdentifier.isEmpty else { return nil }

        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "/?#")

        guard let encodedIdentifier = normalizedIdentifier.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            return nil
        }

        return URL(string: "im:\(encodedIdentifier)")
    }

    private func openMessagesApplication() {
        let applicationURL = URL(fileURLWithPath: "/System/Applications/Messages.app")

        guard NSWorkspace.shared.open(applicationURL) else {
            logger.error("Could not open Messages application")
            return
        }
    }
}
