import SwiftUI

struct NotificationArrivalNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @Environment(\.notchScale) private var scale

    let item: NotificationItem

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Image(systemName: item.effectiveIconName)
                    .font(.system(size: isDynamicIsland ? 14 : 16, weight: .medium))
                    .foregroundStyle(item.level.color)

                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(verbatim: item.summary)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, isDynamicIsland ? 6.scaled(by: scale) : 15.scaled(by: scale))
            .padding(.vertical, 8)
        }
    }
}
