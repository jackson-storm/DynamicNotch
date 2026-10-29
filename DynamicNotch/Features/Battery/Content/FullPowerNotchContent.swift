import SwiftUI

struct FullPowerNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Power.fullPower.id
    let powerService: PowerService
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.Power.fullPower.priority }

    private var style: BatteryNotificationStyle {
        settingsViewModel.battery.fullPowerStyle
    }

    var strokeColor: Color {
        powerService.isLowPowerMode ? .yellow.opacity(0.3) : .green.opacity(0.3)
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        if style == .compact {
            return (top: baseRadius - 4, bottom: baseRadius)
        }
        return (top: 18, bottom: 36)
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 180, height: baseHeight)
        }
        return .init(width: baseWidth + 90, height: baseHeight + 70)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 170, height: baseHeight)
        }
        return .init(width: baseWidth + 210, height: baseHeight + 65)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.4
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            FullPowerNotchView(
                powerService: powerService,
                style: style
            )
        )
    }
}
