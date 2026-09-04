internal import AppKit
import SwiftUI

struct NotificationsNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let items: [AppNotificationItem]
    let onAudioPlaybackStateChanged: (Bool) -> Void
    let onOpenMessage: @MainActor (MessagesMessage) -> Void
    let onOpenMail: @MainActor (MailMessage) -> Void

    var messages: [MessagesMessage] {
        items.compactMap { item in
            guard case .message(let message) = item else { return nil }
            return message
        }
    }

    static let extraWidth: CGFloat = 160
    static let rowSpacing: CGFloat = 10
    static let regularRowHeight: CGFloat = 50
    static let attachmentRowHeight: CGFloat = 64
    static let mailSummaryRowHeight: CGFloat = 52
    static let audioRowHeight: CGFloat = 64
    static let standardBottomPadding: CGFloat = 15
    static let dynamicIslandBottomPadding: CGFloat = 12

    private static let avatarSize: CGFloat = 45
    private static let avatarSpacing: CGFloat = 15
    private static let standardLeadingPadding: CGFloat = 45
    private static let standardTrailingPadding: CGFloat = 45
    private static let dynamicIslandLeadingPadding: CGFloat = 12
    private static let dynamicIslandTrailingPadding: CGFloat = 20

    init(
        items: [AppNotificationItem],
        onAudioPlaybackStateChanged: @escaping (Bool) -> Void = { _ in },
        onOpenMessage: @escaping @MainActor (MessagesMessage) -> Void = { _ in },
        onOpenMail: @escaping @MainActor (MailMessage) -> Void = { _ in }
    ) {
        self.items = items
        self.onAudioPlaybackStateChanged = onAudioPlaybackStateChanged
        self.onOpenMessage = onOpenMessage
        self.onOpenMail = onOpenMail
    }

    init(
        messages: [MessagesMessage],
        onAudioPlaybackStateChanged: @escaping (Bool) -> Void = { _ in },
        onOpen: @escaping @MainActor (MessagesMessage) -> Void
    ) {
        self.items = messages.map(AppNotificationItem.message)
        self.onAudioPlaybackStateChanged = onAudioPlaybackStateChanged
        self.onOpenMessage = onOpen
        self.onOpenMail = { _ in }
    }

    static func rowHeight(for item: AppNotificationItem) -> CGFloat {
        switch item {
        case .message(let message):
            return rowHeight(for: message)
        case .mail(let mail):
            return rowHeight(for: mail)
        }
    }

    static func rowHeight(for message: MessagesMessage) -> CGFloat {
        if hasPlayableAudio(in: message) {
            return audioRowHeight
        }

        if hasAttachmentPreview(in: message) {
            return attachmentRowHeight
        }

        return regularRowHeight
    }

    static func rowHeight(for mail: MailMessage) -> CGFloat {
        let hasSummary = mail.summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasSubject = mail.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        if hasSummary && hasSubject {
            return mailSummaryRowHeight
        }

        return regularRowHeight
    }

    static func hasPlayableAudio(in message: MessagesMessage) -> Bool {
        message.parts.contains { part in
            guard case .attachment(.audio(let attachment)) = part else {
                return false
            }

            return attachment.fileURL != nil
        }
    }

    static func hasAttachmentPreview(in message: MessagesMessage) -> Bool {
        message.parts.contains { part in
            guard case .attachment(let attachment) = part else {
                return false
            }

            switch attachment {
            case .image, .video, .file:
                return true
            case .audio:
                return false
            }
        }
    }

    private var displayedItems: [AppNotificationItem] {
        Array(items.suffix(2))
    }

    private var isQueue: Bool {
        displayedItems.count > 1
    }

    private var hasPlayableAudio: Bool {
        displayedItems.contains { item in
            guard case .message(let message) = item else { return false }
            return Self.hasPlayableAudio(in: message)
        }
    }

    private var hasAttachmentPreview: Bool {
        displayedItems.contains { item in
            guard case .message(let message) = item else { return false }
            return Self.hasAttachmentPreview(in: message)
        }
    }

    private var hasMailWithSummary: Bool {
        displayedItems.contains { item in
            guard case .mail(let mail) = item else { return false }
            return mail.summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    private var dynamicIslandExtraWidth: CGFloat {
        if isQueue || hasPlayableAudio || hasAttachmentPreview || hasMailWithSummary {
            return 210
        }

        return 180
    }

    private func extraHeight(baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        guard let firstItem = displayedItems.first else {
            return 60
        }

        if isQueue {
            return queueExtraHeight(baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        }

        return singleExtraHeight(for: firstItem, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
    }

    private func singleExtraHeight(for item: AppNotificationItem, baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        switch item {
        case .message(let message):
            return singleExtraHeight(for: message, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        case .mail(let mail):
            return singleExtraHeight(for: mail, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        }
    }

    private func singleExtraHeight(for message: MessagesMessage, baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        if Self.hasPlayableAudio(in: message) {
            return isDynamicIsland ? 77 : 80
        }

        if Self.hasAttachmentPreview(in: message) {
            return isDynamicIsland ? 67 : 70
        }

        if hasMultilineText(in: message, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland) {
            return isDynamicIsland ? 72 : 75
        }

        return 60
    }

    private func singleExtraHeight(for mail: MailMessage, baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        let hasSummary = mail.summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasSubject = mail.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        if hasSummary && hasSubject {
            return isDynamicIsland ? 72 : 75
        }

        let fullText = [mail.subject, mail.summary ?? ""].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if hasMultilineString(fullText, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland) {
            return isDynamicIsland ? 72 : 75
        }

        return 60
    }

    private func queueExtraHeight(baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        guard let firstItem = displayedItems.first else {
            return 60
        }

        let bottomPadding = isDynamicIsland ? Self.dynamicIslandBottomPadding : Self.standardBottomPadding
        let firstItemExtraHeight = singleExtraHeight(for: firstItem, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        let firstItemTopPadding = max(firstItemExtraHeight - Self.rowHeight(for: firstItem) - bottomPadding, 0)

        let itemsHeight = displayedItems.reduce(CGFloat.zero) { height, item in
            height + Self.rowHeight(for: item)
        }

        let spacing = Self.rowSpacing * CGFloat(max(displayedItems.count - 1, 0))

        return firstItemTopPadding + itemsHeight + spacing + bottomPadding
    }

    private func hasMultilineText(in message: MessagesMessage, baseWidth: CGFloat, isDynamicIsland: Bool) -> Bool {
        let text = message.parts.compactMap { part -> String? in
            guard case .text(let value) = part else { return nil }
            return value
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return hasMultilineString(text, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
    }

    private func hasMultilineString(_ text: String, baseWidth: CGFloat, isDynamicIsland: Bool) -> Bool {
        guard !text.isEmpty else { return false }

        if text.rangeOfCharacter(from: .newlines) != nil {
            return true
        }

        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let availableWidth = availableTextWidth(baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)

        return textWidth > availableWidth
    }

    private func availableTextWidth(baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        let extraWidth = isDynamicIsland ? dynamicIslandExtraWidth : Self.extraWidth
        let leadingPadding = isDynamicIsland ? Self.dynamicIslandLeadingPadding : Self.standardLeadingPadding
        let trailingPadding = isDynamicIsland ? Self.dynamicIslandTrailingPadding : Self.standardTrailingPadding

        return max(
            baseWidth + extraWidth - leadingPadding - trailingPadding - Self.avatarSize - Self.avatarSpacing,
            0
        )
    }

    var id: String {
        NotchContentRegistry.Notifications.messages.id
    }

    var priority: Int {
        NotchContentRegistry.Notifications.messages.priority
    }

    var usesContentResizeEffect: Bool {
        false
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 28, bottom: 38)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        CGSize(
            width: baseWidth + Self.extraWidth,
            height: baseHeight + extraHeight(baseWidth: baseWidth, isDynamicIsland: false)
        )
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        CGSize(
            width: baseWidth + dynamicIslandExtraWidth,
            height: baseHeight + extraHeight(baseWidth: baseWidth, isDynamicIsland: true)
        )
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * (items.count > 1 ? 0.2 : 0.4)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            NotificationsListView(
                items: displayedItems,
                onAudioPlaybackStateChanged: onAudioPlaybackStateChanged,
                onOpenMessage: onOpenMessage,
                onOpenMail: onOpenMail
            )
        )
    }
}

typealias MessagesNotchContent = NotificationsNotchContent
