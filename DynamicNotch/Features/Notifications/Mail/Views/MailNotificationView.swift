import SwiftUI

struct MailNotificationView: View {

    let message: MailMessage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(message.receivedDate, format: .dateTime.hour().minute())
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: MailNotchContent.extraWidth / 2)
                .padding(.top, 10)

            VStack {
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    Image("appleMail")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.sender)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)

                        Text(message.subject)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .padding(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0))

                        if let summary = message.summary, !summary.isEmpty {
                            Text(summary)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 22)
                .padding(.trailing, 14)
                .padding(.bottom, 12)
            }
        }
        .contentShape(Rectangle())
    }
}
