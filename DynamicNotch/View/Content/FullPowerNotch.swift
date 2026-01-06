import SwiftUI

struct FullPowerNotch: View {
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
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Full Battery")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                    
                    if powerSourceMonitor.isLowPowerMode {
                        Text("\(powerSourceMonitor.batteryLevel)%")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundStyle(.yellow)
                    } else {
                        Text("\(powerSourceMonitor.batteryLevel)%")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
                Text("Your Mac is fully charged.")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.6))
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if powerSourceMonitor.isLowPowerMode {
                yellowIndicator
            } else {
                greenIndicator
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 30)
    }
    
    @ViewBuilder
    private var greenIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.green.opacity(0.2))
                .frame(width: 70, height: 40)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.4))
                    .frame(width: 44, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.gradient)
                            .frame(width: 34, height: 16)
                            .opacity(pulse ? 1 : 0.2)
                            .onAppear {
                                startPulse()
                            }
                    )
                RoundedRectangle(cornerRadius: 10)
                    .fill(.green.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
        }
    }
    
    @ViewBuilder
    private var yellowIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.yellow)
                .frame(width: 70, height: 40)
            
            HStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black)
                    .frame(width: 44, height: 24)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.black)
                    .frame(width: 4, height: 8)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(.yellow.gradient)
                .frame(width: 8, height: 14)
                .offset(x: -15)
        }
    }
}


#Preview {
    VStack(spacing: 30) {
        ZStack {
            FullPowerNotch(powerSourceMonitor: mockBattery(level: 100))
                .frame(width: 300 ,height: 100)
                .background(
                    NotchShape(topCornerRadius: 18, bottomCornerRadius: 36)
                        .fill(.black)
                )
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.red.opacity(0.3), lineWidth: 1)
                .frame(width: 226, height: 38)
                .padding(.bottom, 61)
        }
        
        ZStack {
            FullPowerNotch(powerSourceMonitor: mockBattery(level: 100, lowPower: true))
                .frame(width: 300 ,height: 100)
                .background(
                    NotchShape(topCornerRadius: 18, bottomCornerRadius: 36)
                        .fill(.black)
                )
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.red.opacity(0.3), lineWidth: 1)
                .frame(width: 226, height: 38)
                .padding(.bottom, 61)
        }
    }
    .frame(width: 400, height: 300)
}
