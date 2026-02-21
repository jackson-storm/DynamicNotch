import SwiftUI

struct FullPowerNotchView: View {
    @ObservedObject var powerSourceMonitor: PowerSourceMonitor
    
    @State private var pulse = false
    @State private var showBatteryIndicator = false
    @State private var changeBatteryIndicator = false
    
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
            
            if showBatteryIndicator {
                if powerSourceMonitor.isLowPowerMode {
                    yellowIndicator
                        .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                } else {
                    greenIndicator
                        .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                }
            } else {
                magSafeIndicator
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale))
                    .padding(.trailing, 10)
            }
        }
        .padding(.horizontal, 33)
        .padding(.top, 30)
        .onAppear {
            showBatteryIndicator = true
            changeBatteryIndicator = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if showBatteryIndicator {
                    withAnimation(.spring(duration: 0.4)) {
                        showBatteryIndicator = false
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if changeBatteryIndicator {
                    withAnimation(.spring(duration: 0.2)) {
                        changeBatteryIndicator = false
                    }
                }
            }
        }
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
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 34, height: 14)
                            .opacity(pulse ? 1 : 0.4)
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
                .fill(.yellow.opacity(0.2))
                .frame(width: 70, height: 40)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 44, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.gradient)
                            .frame(width: 34, height: 14)
                            .opacity(pulse ? 1 : 0.4)
                            .onAppear {
                                startPulse()
                            }
                    )
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3, height: 8)
            }
        }
    }
    
    @ViewBuilder
    private var magSafeIndicator: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .frame(width: 40, height: 5)
            
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.gray.opacity(0.2).gradient)
                    .frame(width: 30, height: 40)
                
                Circle()
                    .fill(changeBatteryIndicator ? .orange : .green)
                    .shadow(color: changeBatteryIndicator ? .orange : .green , radius: 5)
                    .frame(width: 5, height: 5)
            }
            
            Rectangle()
                .fill(.white.opacity(0.4))
                .frame(width: 3, height: 32)
        }
    }
}
