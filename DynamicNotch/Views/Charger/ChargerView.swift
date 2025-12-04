import SwiftUI

struct ChargerView: View {
    @EnvironmentObject private var power: PowerSourceMonitor
    
    var body: some View {
        HStack {
            Text("Charging")
                .font(.system(size: 14))
            
            Spacer()
            
            BatteryIndicator(level: power.batteryLevel, isCharging: power.isCharging)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ChargerView()
        .frame(width: 330, height: 38)
        .background(.black)
        .environmentObject(PowerSourceMonitor())
}
