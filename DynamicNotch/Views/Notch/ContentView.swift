import SwiftUI

struct ContentView: View {
    @StateObject private var powerSourceMonitor = PowerSourceMonitor()
    @StateObject private var notchManager = NotchManager()
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var chargerViewModel: ChargerViewModel

    init() {
        let power = PowerSourceMonitor()
        let notch = NotchManager()
        _powerSourceMonitor = StateObject(wrappedValue: power)
        _notchManager = StateObject(wrappedValue: notch)
        _playerViewModel = StateObject(wrappedValue: PlayerViewModel())
        _chargerViewModel = StateObject(wrappedValue: ChargerViewModel(
            powerSourceMonitor: power,
            notchManager: notch
        ))
    }

    var body: some View {
        ZStack {
            NotchContainer()
        }
        .environmentObject(notchManager)
        .environmentObject(playerViewModel)
        .frame(width: 500, height: 300, alignment: .top)
        .onAppear { chargerViewModel.markAsAppeared() }
        .onChange(of: powerSourceMonitor.onACPower) { _, newValue in
            if newValue {
                chargerViewModel.showChargingEvent()
            } else {
                chargerViewModel.hideChargingEvent()
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 500, height: 300)
}
