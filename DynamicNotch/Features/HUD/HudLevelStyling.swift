import SwiftUI

enum HudLevelStyling {
    private static let previewLevel = 72

    static func fillTint(for level: Int, tintStyle: HudIndicatorTintStyle) -> Color {
        let clampedLevel = clamped(level)

        switch tintStyle {
        case .plainWhite:
            return .white.opacity(clampedLevel > 0 ? 0.92 : 0.45)
        case .levelColor:
            return baseTint(for: clampedLevel)
        case .accentColor:
            guard clampedLevel > 0 else {
                return .white.opacity(0.45)
            }

            return .accentColor
        }
    }

    static func fillTint(for level: Int, isEnabled: Bool) -> Color {
        fillTint(for: level, tintStyle: isEnabled ? .levelColor : .plainWhite)
    }

    static func strokeTint(for level: Int, isEnabled: Bool) -> Color {
        let clampedLevel = clamped(level)

        guard isEnabled, clampedLevel > 0 else {
            return .white.opacity(0.2)
        }

        return accentTint(for: clampedLevel).opacity(0.30)
    }

    static func previewFillTint(isEnabled: Bool) -> Color {
        fillTint(for: previewLevel, isEnabled: isEnabled)
    }

    static func previewStrokeTint(isEnabled: Bool) -> Color {
        strokeTint(for: previewLevel, isEnabled: isEnabled)
    }

    private static func baseTint(for level: Int) -> Color {
        guard level > 0 else {
            return .white.opacity(0.45)
        }

        return accentTint(for: level)
    }

    private static func accentTint(for level: Int) -> Color {
        let progress = Double(level) / 100
        let startHue: Double = 0.33
        let endHue: Double = 0.0
        let hue = startHue + (endHue - startHue) * progress

        return Color(
            hue: hue,
            saturation: 0.86,
            brightness: 0.98
        )
    }

    private static func clamped(_ level: Int) -> Int {
        max(0, min(100, level))
    }
}
