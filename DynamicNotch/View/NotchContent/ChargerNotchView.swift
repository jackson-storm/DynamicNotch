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
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 14))
                    .foregroundColor(batteryColor)
                
                HStack(spacing: 1.5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(batteryColor.opacity(0.3))
                        
                        GeometryReader { geo in
                            let clamped = max(0, min(powerSourceMonitor.batteryLevel, 100))
                            let fraction = CGFloat(clamped) / 100
                            let width = fraction * geo.size.width
                            
                            Rectangle()
                                .fill(batteryColor.gradient)
                                .frame(width: max(0, width))
                        }
                    }
                    .frame(width: 28, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(powerSourceMonitor.batteryLevel == 100 ? batteryColor.gradient : batteryColor.opacity(0.5).gradient)
                        .frame(width: 2, height: 6)
                }
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
    }
}
