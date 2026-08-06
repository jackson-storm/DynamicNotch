import SwiftUI

struct MailNotificationView: View {

    let message: MailMessage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(message.receivedDate, format: .dateTime.hour().minute())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
                .padding(.trailing, 14)

            HStack(alignment: .center, spacing: 12) {
                Image("appleMail")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(message.sender)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    Text(message.subject)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if let summary = message.summary,
                       !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 14)
            .padding(.trailing, 62)
            .padding(.top, 22)
            .padding(.bottom, 10)
        }
        .contentShape(Rectangle())
    }
}
