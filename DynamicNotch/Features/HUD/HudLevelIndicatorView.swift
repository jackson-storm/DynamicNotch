import SwiftUI

struct HudLevelIndicatorView: View {
    let level: Int
    let indicatorStyle: HudIndicatorStyle
    let usesColoredLevelTint: Bool
    let barWidth: CGFloat
    let barHeight: CGFloat
    let circleSize: CGFloat
    let circleLineWidth: CGFloat

    private var clampedLevel: Int { max(0, min(100, level)) }
    private var progress: CGFloat { CGFloat(clampedLevel) / 100 }

    private var levelTint: Color {
        HudLevelStyling.fillTint(for: clampedLevel, isEnabled: true)
    }

    private var activeLevelTint: Color {
        usesColoredLevelTint ? levelTint : HudLevelStyling.fillTint(for: clampedLevel, isEnabled: false)
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
                    .shadow(color: activeLevelTint.opacity(0.35), radius: 5, y: 0)
            }
    }

    private var circleIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.04))

            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: circleLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    circleFill,
                    style: StrokeStyle(lineWidth: circleLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: activeLevelTint.opacity(0.35), radius: 5, y: 0)
        }
        .frame(width: circleSize, height: circleSize)
    }
}
