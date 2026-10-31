import SwiftUI

struct LowPowerNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Power.lowPower.id
    let powerService: PowerService
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.Power.lowPower.priority }

    private var style: BatteryNotificationStyle {
        settingsViewModel.battery.lowPowerStyle
    }

    var strokeColor: Color {
        powerService.isLowPowerMode ? .yellow.opacity(0.3) : .red.opacity(0.3)
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        if style == .compact {
            return (top: baseRadius - 4, bottom: baseRadius)
        }
        return (top: 22, bottom: 40)
    }

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 180, height: baseHeight)
        }
        return .init(width: baseWidth + 130, height: baseHeight + 75)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 170, height: baseHeight)
        }
        return .init(width: baseWidth + 230, height: baseHeight + 60)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.4
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(
            LowPowerNotchView(
                powerService: powerService,
                style: style
            )
        )
    }
}
