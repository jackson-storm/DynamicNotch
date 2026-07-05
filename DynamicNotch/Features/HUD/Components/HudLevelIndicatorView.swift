import SwiftUI

struct HudLevelIndicatorView: View {
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    let tintStyle: HudIndicatorTintStyle
    let showsGlow: Bool
    let barWidth: CGFloat
    let barHeight: CGFloat
    let circleSize: CGFloat
    let circleLineWidth: CGFloat

    init(
        level: Int,
        indicatorStyle: HudIndicatorStyle,
        tintStyle: HudIndicatorTintStyle,
        showsGlow: Bool,
        barWidth: CGFloat,
        barHeight: CGFloat,
        circleSize: CGFloat = 16,
        circleLineWidth: CGFloat = 3
    ) {
        self.level = level
        self.indicatorStyle = indicatorStyle
        self.tintStyle = tintStyle
        self.showsGlow = showsGlow
        self.barWidth = barWidth
        self.barHeight = barHeight
        self.circleSize = circleSize
        self.circleLineWidth = circleLineWidth
    }

    private var clampedLevel: Int { max(0, min(100, level)) }
    private var progress: CGFloat { CGFloat(clampedLevel) / 100 }

    private var activeLevelTint: Color {
        HudLevelStyling.fillTint(for: clampedLevel, tintStyle: tintStyle)
    }

    private var glowColor: Color {
        showsGlow ? activeLevelTint.opacity(0.8) : .clear
    }

    private var glowRadius: CGFloat {
        showsGlow ? 10 : 0
    }

    private var barFill: LinearGradient {
        LinearGradient(
            colors: [
                activeLevelTint.opacity(0.82),
                activeLevelTint
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var circleFill: AngularGradient {
        AngularGradient(
            colors: [
                activeLevelTint.opacity(0.55),
                activeLevelTint,
                activeLevelTint.opacity(0.8)
            ],
            center: .center
        )
    }

    var body: some View {
        Group {
            switch indicatorStyle {
            case .bar:
                barIndicator
            case .circle:
                circleIndicator
            }
        }
        .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: clampedLevel)
    }

    private var barIndicator: some View {
        RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
            .fill(Color.white.opacity(0.18))
            .frame(width: barWidth, height: barHeight)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                    .fill(barFill)
                    .frame(width: barWidth * progress, height: barHeight)
                    .shadow(color: glowColor, radius: glowRadius)
            }
    }

    private var circleIndicator: some View {
        CircleIndicatorView(
            progress: progress,
            size: circleSize,
            lineWidth: circleLineWidth,
            foregroundStyle: circleFill,
            glowColor: glowColor,
            glowRadius: glowRadius
        )
    }
}
