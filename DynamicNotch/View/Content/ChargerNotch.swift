import SwiftUI

struct ChargerNotch: View {
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
                .foregroundColor(.white)
            
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
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 10) {
        ZStack {
            ChargerNotch(powerSourceMonitor: mockBattery(level: 100))
                .frame(width: 405, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.red.opacity(0.3), lineWidth: 1)
                .frame(width: 226, height: 38)
        }
        
        ZStack {
            ChargerNotch(powerSourceMonitor: mockBattery(level: 20))
                .frame(width: 405, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.red.opacity(0.3), lineWidth: 1)
                .frame(width: 226, height: 38)
        }
        
        ZStack {
            ChargerNotch(powerSourceMonitor: mockBattery(level: 50, lowPower: true))
                .frame(width: 405, height: 38)
                .background(
                    NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                        .fill(.black)
                )
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.red.opacity(0.3), lineWidth: 1)
                .frame(width: 226, height: 38)
        }
    }
    .frame(width: 450, height: 200)
}
