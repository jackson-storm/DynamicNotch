import SwiftUI

struct NotchContentView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerViewModel: PowerViewModel
    
    var body: some View {
        Group {
            switch notchViewModel.state.content {
            case .none:
                Color.clear
            case .music:
                PlayerNotch()
            case .charger:
                ChargerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
            case .lowPower:
                LowPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
            case .fullPower:
                FullPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
            case .audioHardware:
                AudioHardwareNotch()
            case .systemHud:
                SystemHudNotch(notchViewModel: notchViewModel)
            }
        }
    }
}
