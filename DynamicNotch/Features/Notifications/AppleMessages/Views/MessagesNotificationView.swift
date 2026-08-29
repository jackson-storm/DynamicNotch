import SwiftUI

struct MessagesNotificationView: View {
    let message: MessagesMessage

    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack {
            Spacer()
            content
        }
        .padding(.leading, isDynamicIsland ? 12 : 35)
        .padding(.trailing, isDynamicIsland ? 20 : 40)
        .padding(.bottom, isDynamicIsland ? 12 : 15)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("appleMessages")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(message.sender)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Text(message.receivedDate, format: .dateTime.hour().minute())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(message.text)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                } else {
                    Text("Empty message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(message.rowID)
        .transition(.blurAndFade.combined(with: .opacity).animation(.spring(response: 0.6)))
    }
}
