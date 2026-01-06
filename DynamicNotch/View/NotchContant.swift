import SwiftUI

struct NotchContant: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var powerViewModel: PowerViewModel
    
    var body: some View {
        if notchViewModel.state.content != .none {
            Group {
                switch notchViewModel.state.content {
                case .music:
                    PlayerNotch()
                case .charger:
                    ChargerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                case .lowPower:
                    LowPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                case .fullPower:
                    FullPowerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                case .systemHud:
                    SystemHudNotch(notchViewModel: notchViewModel)
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct Controller: View {
    @ObservedObject var notchViewModel: NotchViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            Button("Music") {
                notchViewModel.send(.show(.music))
            }
            Button("Charger") {
                notchViewModel.send(.show(.charger))
            }
            Button("Low Power") {
                notchViewModel.send(.show(.lowPower))
            }
            Button("Full Power") {
                notchViewModel.send(.show(.fullPower))
            }
            Button("Sound Bar") {
                notchViewModel.send(.show(.systemHud(.volume)))
            }
            Button("Display Bar") {
                notchViewModel.send(.show(.systemHud(.display)))
            }
            Button("Keyboard Bar") {
                notchViewModel.send(.show(.systemHud(.keyboard)))
            }
            Button("Hide") {
                notchViewModel.send(.hide)
            }
        }
        .padding()
    }
}
