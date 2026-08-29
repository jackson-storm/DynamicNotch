internal import AppKit
import SwiftUI

@MainActor
struct MessagesNotificationView: View {
    let messages: [MessagesMessage]
    let onAudioPlaybackStateChanged: (Bool) -> Void
    let onOpen: (MessagesMessage) -> Void

    @Environment(\.isDynamicIsland) private var isDynamicIsland

    init(messages: [MessagesMessage], onAudioPlaybackStateChanged: @escaping (Bool) -> Void = { _ in }, onOpen: @escaping (MessagesMessage) -> Void = { _ in }) {
        self.messages = messages
        self.onAudioPlaybackStateChanged = onAudioPlaybackStateChanged
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            messageList
        }
        .padding(.leading, isDynamicIsland ? 12 : 35)
        .padding(.trailing, isDynamicIsland ? 20 : 40)
        .padding(.bottom, isDynamicIsland ? MessagesNotchContent.dynamicIslandBottomPadding : MessagesNotchContent.standardBottomPadding)
    }

    private var messageList: some View {
        VStack(spacing: MessagesNotchContent.rowSpacing) {
            ForEach(messages) { message in
                MessagesNotificationRow(message: message, onAudioPlaybackStateChanged: onAudioPlaybackStateChanged, onOpen: onOpen)
                    .frame(height: messages.count > 1 ? MessagesNotchContent.rowHeight(for: message) : nil)
                    .transition(messageTransition)
            }
        }
        .animation(.spring(response: 0.46, dampingFraction: 0.86, blendDuration: 0.12), value: messages.map(\.id))
    }

    private var messageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.96, anchor: .bottom)),
            removal: .move(edge: .top)
                .combined(with: .blurAndFade)
                .combined(with: .scale(scale: 0.94, anchor: .top))
        )
    }
}

@MainActor
private struct MessagesNotificationRow: View {
    let message: MessagesMessage
    let onAudioPlaybackStateChanged: (Bool) -> Void
    let onOpen: (MessagesMessage) -> Void

    private let avatarSize: CGFloat = 33
    private let avatarSpacing: CGFloat = 21
    private let contentSpacing: CGFloat = 3.5

    var body: some View {
        Group {
            if let audioAttachment, let fileURL = audioAttachment.fileURL {
                audioContent(fileURL: fileURL, duration: audioAttachment.duration)
            } else if previewAttachments.isEmpty {
                regularContent
            } else {
                attachmentContent
            }
        }
    }

    private var regularContent: some View {
        Button(action: openMessage) {
            HStack(alignment: .center, spacing: avatarSpacing) {
                avatar

                VStack(alignment: .leading, spacing: contentSpacing) {
                    header
                    previewText(lineLimit: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }

    private var attachmentContent: some View {
        Button(action: openMessage) {
            VStack(alignment: .trailing, spacing: contentSpacing) {
                timestamp

                HStack(alignment: .center, spacing: avatarSpacing) {
                    avatar

                    VStack(alignment: .leading, spacing: contentSpacing) {
                        titleText
                        previewText(lineLimit: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: MessagesAttachmentPreview.thumbnailSize, alignment: .center)

                    MessagesAttachmentPreview(attachments: previewAttachments)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }

    private func audioContent(fileURL: URL, duration: TimeInterval?) -> some View {
        HStack(alignment: .center, spacing: avatarSpacing) {
            Button(action: openMessage) {
                avatar
                    .contentShape(Circle())
            }
            .buttonStyle(PlaybackSourceButtonStyle())

            VStack(alignment: .leading, spacing: contentSpacing) {
                Button(action: openMessage) {
                    header
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlaybackSourceButtonStyle())

                MessagesAudioMessageView(fileURL: fileURL, duration: duration, onPlaybackStateChanged: onAudioPlaybackStateChanged)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            titleText

            Spacer(minLength: 8)

            timestamp
        }
        .frame(maxWidth: .infinity)
    }

    private var titleText: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
    }

    private var timestamp: some View {
        Text(message.receivedDate, format: .dateTime.hour().minute())
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private func previewText(lineLimit: Int) -> some View {
        Text(preview)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var avatar: some View {
        if message.sender.isKnownContact {
            contactAvatar
        } else {
            Image("messages")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: avatarSize, height: avatarSize)
        }
    }

    private var contactAvatar: some View {
        Group {
            if let avatarData = message.sender.avatarData, let image = NSImage(data: avatarData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))

                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            messagesBadge
                .offset(x: 6)
        }
    }

    private var messagesBadge: some View {
        Image(systemName: "message.fill")
            .font(.system(size: 6, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(Color.green, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(.black.opacity(0.3), lineWidth: 1)
            }
    }

    private var attachments: [MessagesAttachment] {
        message.parts.compactMap { part in
            guard case .attachment(let attachment) = part else { return nil }
            return attachment
        }
    }

    private var previewAttachments: [MessagesAttachment] {
        attachments.filter { attachment in
            switch attachment {
            case .image, .video, .file:
                true
            case .audio:
                false
            }
        }
    }

    private var audioAttachment: MessagesAudioAttachment? {
        for attachment in attachments {
            guard case .audio(let audioAttachment) = attachment else {
                continue
            }

            return audioAttachment
        }

        return nil
    }

    private var messageText: String {
        message.parts.compactMap { part -> String? in
            guard case .text(let value) = part else { return nil }
            return value
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var title: String {
        if let conversation = message.conversation,
           conversation.isGroup,
           let displayName = conversation.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !displayName.isEmpty {
            return displayName
        }

        return message.sender.displayName
    }

    private var preview: String {
        if !messageText.isEmpty {
            return messageText
        }

        guard let attachment = attachments.first else {
            return ""
        }

        switch attachment {
        case .image:
            return String(localized: "messages.notification.photo")
        case .video:
            return String(localized: "messages.notification.video")
        case .audio:
            return String(localized: "messages.notification.audio")
        case .file(let file):
            return file.filename ?? String(localized: "messages.notification.file")
        }
    }

    private var initials: String {
        message.sender.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }

    private func openMessage() {
        onOpen(message)
    }
}
