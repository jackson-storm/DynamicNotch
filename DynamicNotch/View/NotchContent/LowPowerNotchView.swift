import SwiftUI

struct LowPowerNotchView: View {
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
                VStack(alignment: .leading, spacing: 3) {
                    title
                    description
                }
                
                Spacer()
                
                if powerSourceMonitor.isLowPowerMode {
                    yellowIndicator
                } else {
                    redIndicator
                }
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 45)
    }
    
    @ViewBuilder
    var title: some View {
        HStack {
            Text("Battery Low")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if powerSourceMonitor.isLowPowerMode {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundStyle(.yellow)
            } else {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
    }
    
    @ViewBuilder
    var description: some View {
        if powerSourceMonitor.isLowPowerMode {
            Text("Low Power Mode enabled")
                .foregroundColor(.yellow)
            + Text(", it is recommended to charge it.")
                .foregroundColor(.gray.opacity(0.6))
                .font(.system(size: 10, weight: .medium))
        } else {
            Text("Turn on Low Power Mode or it is recommended to charge it.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray.opacity(0.6))
                .lineLimit(2)
        }
    }
    
    @ViewBuilder
    var redIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.red.opacity(0.2))
                .frame(width: 70, height: 40)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.4))
                    .frame(width: 40, height: 24)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.gradient)
                .frame(width: 8, height: 14)
                .opacity(pulse ? 1 : 0.3)
                .offset(x: -15)
                .onAppear { startPulse() }
            
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.red.opacity(0.9).gradient, lineWidth: 1.5)
                .frame(width: pulse ? 8 : 30, height: pulse ? 14 : 32)
                .offset(x: -15)
                .opacity(pulse ? 0.3 : 1)
        }
    }
    
    @ViewBuilder
    var yellowIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.yellow.opacity(0.2))
                .frame(width: 70, height: 40)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 40, height: 24)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.yellow.gradient)
                .frame(width: 8, height: 14)
                .offset(x: -15)
        }
    }
}
