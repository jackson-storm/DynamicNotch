internal import AppKit
import SwiftUI

@MainActor
struct MailNotificationRow: View {
    let mail: MailMessage
    let onOpen: (MailMessage) -> Void

    private let avatarSize: CGFloat = 50
    private let avatarSpacing: CGFloat = 12

    private var senderInfo: MailSenderInfo {
        mail.senderInfo
    }

    var body: some View {
        Button(action: { onOpen(mail) }) {
            HStack(alignment: .center, spacing: avatarSpacing) {
                avatar

                VStack(alignment: .leading, spacing: 3) {
                    header
                    contentPreview
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(senderInfo.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(mail.receivedDate, format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var contentPreview: some View {
        let trimmedSubject = mail.subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = mail.summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasSummary = !trimmedSummary.isEmpty

        if hasSummary && !trimmedSubject.isEmpty {
            VStack(alignment: .leading, spacing: 1.5) {
                Text(trimmedSubject)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(trimmedSummary)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.trailing, 5)
            
        } else {
            let displayText = !trimmedSubject.isEmpty
                ? trimmedSubject
                : (!trimmedSummary.isEmpty ? trimmedSummary : String(localized: "settings.notifications.appleMail.noSubject"))

            Text(displayText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(trimmedSubject.isEmpty && !hasSummary ? Color.secondary : Color.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.trailing, 5)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if senderInfo.isKnownContact {
            contactAvatar
        } else {
            Image("appleMail")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: avatarSize, height: avatarSize)
        }
    }

    private var contactAvatar: some View {
        Group {
            if let avatarData = senderInfo.avatarData, let image = NSImage(data: avatarData) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.14))

                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            Image("appleMail")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .offset(x: 6, y: 2)
        }
    }
    
    private var initials: String {
        senderInfo.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}
