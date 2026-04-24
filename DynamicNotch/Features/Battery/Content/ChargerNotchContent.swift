import SwiftUI

enum PowerEvent: Equatable {
    case charger
    case lowPower
    case fullPower
}

struct ChargerNotchContent: NotchContentProtocol {
    let id = "battery.charger"
    
    let powerService: PowerService
    let settingsViewModel: SettingsViewModel
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
            .white.opacity(0.2) : (powerService.isLowPowerMode ? .yellow.opacity(0.3) : .green.opacity(0.3))
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(ChargerNotchView(powerService: powerService))
    }
}
