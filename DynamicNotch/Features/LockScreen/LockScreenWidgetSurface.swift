import SwiftUI

struct LockScreenWidgetSurface: View {
    let style: LockScreenWidgetAppearanceStyle
    let tintStyle: LockScreenWidgetTintStyle
    let appTint: AppTint
    let brightness: Double
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        baseSurface(shape: shape)
            .overlay {
                if let tintColor = tintStyle.resolvedColor(appTint: appTint) {
                    shape
                        .fill(tintColor.opacity(tintOpacity))
                }
            }
            .overlay {
                shape
                    .fill(brightnessOverlayColor)
            }
            .overlay {
                shape
                    .stroke(strokeColor, lineWidth: 1)
            }
    }

    @ViewBuilder
    private func baseSurface(shape: RoundedRectangle) -> some View {
        switch style {
        case .ultraThinMaterial:
            shape.fill(.ultraThinMaterial)

        case .ultraThickMaterial:
            shape.fill(.ultraThickMaterial)

        case .liquidGlass:
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: shape)
            } else {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.14),
                                    .white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
            }
        }
    }

    private var tintOpacity: Double {
        switch style {
        case .ultraThinMaterial:
            return 0.14
        case .ultraThickMaterial:
            return 0.18
        case .liquidGlass:
            return 0.10
        }
    }

    private var brightnessOverlayColor: Color {
        let clampedBrightness = min(
            max(brightness, LockScreenSettings.widgetBackgroundBrightnessRange.lowerBound),
            LockScreenSettings.widgetBackgroundBrightnessRange.upperBound
        )
        let delta = clampedBrightness - 1

        if delta >= 0 {
            return .white.opacity(delta * 0.42)
        }

        return .black.opacity(abs(delta) * 0.55)
    }

    private var strokeColor: Color {
        if let tintColor = tintStyle.resolvedColor(appTint: appTint) {
            switch style {
            case .ultraThinMaterial:
                return tintColor.opacity(0.24)
            case .ultraThickMaterial:
                return tintColor.opacity(0.28)
            case .liquidGlass:
                return tintColor.opacity(0.18)
            }
        }

        switch style {
        case .ultraThinMaterial:
            return .white.opacity(0.15)
        case .ultraThickMaterial:
            return .white.opacity(0.18)
        case .liquidGlass:
            return .white.opacity(0.12)
        }
    }
}
