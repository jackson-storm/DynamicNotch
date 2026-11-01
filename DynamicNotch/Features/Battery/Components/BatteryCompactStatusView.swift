import SwiftUI

struct BatteryCompactStatusView: View {
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.notchScale) private var scale

    let title: String
    let batteryLevel: Int
    let tint: Color

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: isNotchlessScreen ? 13 : 14))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            HStack(spacing: 6) {
                Text("\(batteryLevel)%")
                    .font(.system(size: isNotchlessScreen ? 13 : 14))
                    .foregroundStyle(tint.gradient)

                HStack(spacing: 1.5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: isNotchlessScreen ? 5 : 6, style: .continuous)
                            .fill(tint.opacity(0.3))

                        GeometryReader { geo in
                            let clamped = max(0, min(batteryLevel, 100))
                            let fraction = CGFloat(clamped) / 100
                            let width = fraction * geo.size.width

                            Rectangle()
                                .fill(tint.gradient)
                                .frame(width: max(0, width))
                        }
                    }
                    .frame(width: isNotchlessScreen ? 26 : 28, height: isNotchlessScreen ? 14 : 16)
                    .clipShape(RoundedRectangle(cornerRadius: isNotchlessScreen ? 5 : 6, style: .continuous))

                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(batteryLevel == 100 ? tint.gradient : tint.opacity(0.3).gradient)
                        .frame(width: 2, height: 6)
                }
            }
        }
        .padding(.leading, isNotchlessScreen ? 7.scaled(by: scale) : 16.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 6.scaled(by: scale) : 16.scaled(by: scale))
    }
}
