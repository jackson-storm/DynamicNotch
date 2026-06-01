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
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.battery.isFullPowerDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        (powerService.isLowPowerMode ? .yellow.opacity(0.3) : .green.opacity(0.3))
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 180, height: baseHeight)
        }
        return .init(width: baseWidth + 80, height: baseHeight + 70)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        if style == .compact {
            return (top: baseRadius - 4, bottom: baseRadius)
        }
        return (top: 18, bottom: 36)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if style == .compact {
            return .init(width: baseWidth + 150, height: baseHeight)
        }
        return .init(width: baseWidth + 130, height: baseHeight + 60)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            FullPowerNotchView(
                powerService: powerService,
                style: style
            )
        )
    }
}
