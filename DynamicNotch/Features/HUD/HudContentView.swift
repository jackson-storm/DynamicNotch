import SwiftUI

struct HudContentView: View {
    @Environment(\.notchScale) var scale

    let image: String
    let text: String
    let level: Int

    private var indicatorWidth: CGFloat { 64 }
    private var indicatorHeight: CGFloat { 6 }
    private var clampedLevel: Int { max(0, min(100, level)) }
    private var filledIndicatorWidth: CGFloat { indicatorWidth * CGFloat(clampedLevel) / 100 }

    private var indicatorFill: some ShapeStyle {
        LinearGradient(
            colors: [
                levelTint.opacity(0.82),
                levelTint,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var levelTint: Color {
        guard clampedLevel > 0 else {
            return .white.opacity(0.45)
        }

        let progress = Double(clampedLevel) / 100
        let startHue: Double = 0.33
        let endHue: Double = 0.0
        let hue = startHue + (endHue - startHue) * progress

        return Color(
            hue: hue,
            saturation: 0.86,
            brightness: 0.98
        )
    }

    var body: some View {
        HStack {
            HStack {
                Image(systemName: image)
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 10) {
                AnimatedLevelText(level: clampedLevel, fontSize: 14)
                indicator
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
    }

    @ViewBuilder
    private var indicator: some View {
        RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: indicatorHeight / 2, style: .continuous)
                    .fill(indicatorFill)
                    .frame(width: filledIndicatorWidth, height: indicatorHeight)
                    .shadow(color: levelTint.opacity(0.35), radius: 5, y: 0)
            }
            .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: clampedLevel)
    }
}
