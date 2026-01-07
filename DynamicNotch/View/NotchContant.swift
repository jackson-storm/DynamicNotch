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
                notchViewModel.send(.showActive(.music))
            }
            Button("Charger") {
                notchViewModel.send(.showTemporary(.charger))
            }
            Button("Low Power") {
                notchViewModel.send(.showTemporary(.lowPower))
            }
            Button("Full Power") {
                notchViewModel.send(.showTemporary(.fullPower))
            }
            Button("Sound Bar") {
                notchViewModel.send(.showTemporary(.systemHud(.volume)))
            }
            Button("Display Bar") {
                notchViewModel.send(.showTemporary(.systemHud(.display)))
            }
            Button("Keyboard Bar") {
                notchViewModel.send(.showTemporary(.systemHud(.keyboard)))
            }
            Button("Hide") {
                notchViewModel.send(.hideTemporary)
                notchViewModel.send(.showActive(.none))
            }
        }
        .padding()
    }
}
