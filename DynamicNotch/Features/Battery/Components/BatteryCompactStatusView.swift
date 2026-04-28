import SwiftUI

struct BatteryCompactStatusView: View {
    @Environment(\.notchScale) private var scale

    let title: String
    let batteryLevel: Int
    let tint: Color

    var body: some View {
        HStack {
            Text(verbatim: title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            HStack(spacing: 6) {
                Text("\(batteryLevel)%")
                    .font(.system(size: 14))
                    .foregroundStyle(tint.gradient)

                HStack(spacing: 1.5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
                    .frame(width: 28, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(batteryLevel == 100 ? tint.gradient : tint.opacity(0.3).gradient)
                        .frame(width: 2, height: 6)
                }
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
    }
}
