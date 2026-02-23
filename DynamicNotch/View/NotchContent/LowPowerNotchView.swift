import SwiftUI

struct LowPowerNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var powerSourceMonitor: PowerSourceMonitor
    @State private var pulse = false
    
    private func startPulse() {
        pulse = false
        withAnimation(
            .easeInOut(duration: 1)
            .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 3.scaled(by: scale)) {
                    HStack {
                        Text("Battery Low")
                            .font(.system(size: 14.scaled(by: scale)))
                            .fontWeight(.semibold)
                        
                        if powerSourceMonitor.isLowPowerMode {
                            Text("\(powerSourceMonitor.batteryLevel)%")
                                .font(.system(size: 14.scaled(by: scale)))
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                        } else {
                            Text("\(powerSourceMonitor.batteryLevel)%")
                                .font(.system(size: 14.scaled(by: scale)))
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        }
                    }
                    if powerSourceMonitor.isLowPowerMode {
                        Text("Low Power Mode enabled")
                            .foregroundColor(.yellow)
                        
                        + Text(", it is recommended to charge it.")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 11.scaled(by: scale)))
                            .fontWeight(.medium)
                        
                    } else {
                        Text("Turn on Low Power Mode or it is recommended to charge it.")
                            .font(.system(size: 11.scaled(by: scale)))
                            .foregroundStyle(.gray.opacity(0.6))
                            .fontWeight(.medium)
                            .lineLimit(2)
                    }
                }
                if powerSourceMonitor.isLowPowerMode {
                    yellowIndicator
                } else {
                    redIndicator
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var redIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30.scaled(by: scale))
                .fill(.red.opacity(0.2))
                .frame(width: 80.scaled(by: scale), height: 50.scaled(by: scale))
            
            HStack(spacing: 2.scaled(by: scale)) {
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.red.opacity(0.4))
                    .frame(width: 44.scaled(by: scale), height: 24.scaled(by: scale))
                
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.red.opacity(0.4))
                    .frame(width: 3.scaled(by: scale), height: 8.scaled(by: scale))
            }
            
            RoundedRectangle(cornerRadius: 8.scaled(by: scale))
                .fill(Color.red.gradient)
                .frame(width: 8.scaled(by: scale), height: 14.scaled(by: scale))
                .opacity(pulse ? 1 : 0.3)
                .offset(x: -15.scaled(by: scale))
                .onAppear {
                    startPulse()
                }
            
            RoundedRectangle(cornerRadius: 30.scaled(by: scale))
                .stroke(Color.red.opacity(0.9).gradient, lineWidth: 1.5)
                .frame(width: pulse ? 8.scaled(by: scale) : 30.scaled(by: scale), height: pulse ? 14.scaled(by: scale) : 32.scaled(by: scale))
                .offset(x: -15)
                .opacity(pulse ? 0.3 : 1)
        }
    }
    
    @ViewBuilder
    private var yellowIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30.scaled(by: scale))
                .fill(.yellow.opacity(0.2))
                .frame(width: 80.scaled(by: scale), height: 50.scaled(by: scale))
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 44.scaled(by: scale), height: 24.scaled(by: scale))
                
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3.scaled(by: scale), height: 8.scaled(by: scale))
            }
            
            RoundedRectangle(cornerRadius: 8.scaled(by: scale))
                .fill(.yellow.gradient)
                .frame(width: 8.scaled(by: scale), height: 14.scaled(by: scale))
                .offset(x: -15.scaled(by: scale))
        }
    }
}
