internal import AppKit
import SwiftUI

struct MessagesNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let messages: [MessagesMessage]
    let onAudioPlaybackStateChanged: (Bool) -> Void
    let onOpen: @MainActor (MessagesMessage) -> Void

    static let extraWidth: CGFloat = 160
    static let rowSpacing: CGFloat = 10
    static let regularRowHeight: CGFloat = 50
    static let attachmentRowHeight: CGFloat = 52
    static let audioRowHeight: CGFloat = 64
    static let standardBottomPadding: CGFloat = 15
    static let dynamicIslandBottomPadding: CGFloat = 12

    private static let avatarSize: CGFloat = 33
    private static let avatarSpacing: CGFloat = 21
    private static let standardLeadingPadding: CGFloat = 35
    private static let standardTrailingPadding: CGFloat = 40
    private static let dynamicIslandLeadingPadding: CGFloat = 12
    private static let dynamicIslandTrailingPadding: CGFloat = 20

    init(messages: [MessagesMessage], onAudioPlaybackStateChanged: @escaping (Bool) -> Void = { _ in }, onOpen: @escaping @MainActor (MessagesMessage) -> Void) {
        self.messages = messages
        self.onAudioPlaybackStateChanged = onAudioPlaybackStateChanged
        self.onOpen = onOpen
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

    private var displayedMessages: [MessagesMessage] {
        Array(messages.suffix(2))
    }

    private var isQueue: Bool {
        displayedMessages.count > 1
    }

    private var hasPlayableAudio: Bool {
        displayedMessages.contains { message in
            Self.hasPlayableAudio(in: message)
        }
    }

    private var hasAttachmentPreview: Bool {
        displayedMessages.contains { message in
            Self.hasAttachmentPreview(in: message)
        }
    }

    private var dynamicIslandExtraWidth: CGFloat {
        if isQueue || hasPlayableAudio || hasAttachmentPreview {
            return 210
        }

        return 180
    }

    private func extraHeight(baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        guard let firstMessage = displayedMessages.first else {
            return 60
        }

        if isQueue {
            return queueExtraHeight(baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        }

        return singleExtraHeight(for: firstMessage, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
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

    private func queueExtraHeight(baseWidth: CGFloat, isDynamicIsland: Bool) -> CGFloat {
        guard let firstMessage = displayedMessages.first else {
            return 60
        }

        let bottomPadding = isDynamicIsland ? Self.dynamicIslandBottomPadding : Self.standardBottomPadding
        let firstMessageExtraHeight = singleExtraHeight(for: firstMessage, baseWidth: baseWidth, isDynamicIsland: isDynamicIsland)
        let firstMessageTopPadding = max(firstMessageExtraHeight - Self.rowHeight(for: firstMessage) - bottomPadding, 0)

        let messagesHeight = displayedMessages.reduce(CGFloat.zero) { height, message in
            height + Self.rowHeight(for: message)
        }

        let spacing = Self.rowSpacing * CGFloat(max(displayedMessages.count - 1, 0))

        return firstMessageTopPadding + messagesHeight + spacing + bottomPadding
    }

    private func hasMultilineText(in message: MessagesMessage, baseWidth: CGFloat, isDynamicIsland: Bool) -> Bool {
        let text = message.parts.compactMap { part -> String? in
            guard case .text(let value) = part else { return nil }
            return value
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

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
        (top: 20, bottom: 38)
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
        baseHeight * 0.3
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(MessagesNotificationView(messages: displayedMessages, onAudioPlaybackStateChanged: onAudioPlaybackStateChanged, onOpen: onOpen))
    }
}
