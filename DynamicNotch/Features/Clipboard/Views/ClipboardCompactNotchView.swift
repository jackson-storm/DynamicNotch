import SwiftUI

struct ClipboardCompactNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @Environment(\.notchScale) private var scale

    let item: ClipboardHistoryItem

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: item.payload.kind.systemImage)
                .font(.system(size: isDynamicIsland ? 14 : 17, weight: .semibold))
                .foregroundStyle(ClipboardDesign.accent)

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(verbatim: "Copied")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                if !isDynamicIsland {
                    Text(verbatim: item.payload.kind.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .padding(.leading, isDynamicIsland ? 7.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: scale) : 15.scaled(by: scale))
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Copied \(item.payload.kind.title). Open clipboard history.")
    }
}

enum ClipboardDesign {
    static let accent = Color(red: 0.40, green: 0.84, blue: 0.72)
    static let warning = Color(red: 1.00, green: 0.63, blue: 0.28)
    static let elevatedSurface = Color.white.opacity(0.075)
    static let hoverSurface = Color.white.opacity(0.12)
    static let currentSurface = accent.opacity(0.105)
}
