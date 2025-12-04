import SwiftUI

struct NotchContentView: View {
    @StateObject private var layout = NotchLayoutViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var power = PowerSourceMonitor()
   
    var body: some View {
        ZStack(alignment: .top) {
          
            if power.onACPower {
                NotchContainer(kind: .charger) {
                    ChargerView()
                }
            } else {
                NotchContainer(kind: .defaultNotch) {
                    DefaultNotchView()
                }
            }
        }
        .frame(width: 500, height: 300, alignment: .top)
        .environmentObject(layout)
        .environmentObject(playerViewModel)
        .environmentObject(power)
    }
}

#Preview {
    NotchContentView()
        .frame(width: 500, height: 300)
}


struct DefaultNotchView: View {
    var body: some View {
        EmptyView()
    }
}

