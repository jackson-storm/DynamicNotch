import SwiftUI

struct ChargerNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var powerSourceMonitor: PowerSourceMonitor
    
    private var batteryColor: Color {
        if powerSourceMonitor.isLowPowerMode {
            return .yellow
        } else if powerSourceMonitor.batteryLevel <= 20 {
            return .red
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack {
            Text("Charging")
                .font(.system(size: 14.scaled(by: scale)))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 14.scaled(by: scale)))
                    .foregroundColor(batteryColor)
                
                HStack(spacing: 1.5.scaled(by: scale)) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6.scaled(by: scale), style: .continuous)
                            .fill(batteryColor.opacity(0.3))
                        
                        GeometryReader { geo in
                            let clamped = max(0, min(powerSourceMonitor.batteryLevel, 100))
                            let fraction = CGFloat(clamped) / 100
                            let width = fraction * geo.size.width
                            
                            Rectangle()
                                .fill(batteryColor.gradient)
                                .frame(width: max(0, width.scaled(by: scale)))
                        }
                    }
                    .frame(width: 28.scaled(by: scale), height: 16.scaled(by: scale))
                    .clipShape(RoundedRectangle(cornerRadius: 6.scaled(by: scale), style: .continuous))
                    
                    RoundedRectangle(cornerRadius: 1.5.scaled(by: scale), style: .continuous)
                        .fill(powerSourceMonitor.batteryLevel == 100 ? batteryColor.gradient : batteryColor.opacity(0.5).gradient)
                        .frame(width: 2.scaled(by: scale), height: 6.scaled(by: scale))
                }
            }
        }
        .padding(.horizontal, 8.scaled(by: scale))
    }
}
