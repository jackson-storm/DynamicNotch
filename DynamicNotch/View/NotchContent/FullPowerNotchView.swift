import SwiftUI

struct FullPowerNotchView: View {
    @Environment(\.notchScale) var scale
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
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 3.scaled(by: scale)) {
                    HStack {
                        Text("Full Battery")
                            .font(.system(size: 14.scaled(by: scale)))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        if powerSourceMonitor.isLowPowerMode {
                            Text("\(powerSourceMonitor.batteryLevel)%")
                                .font(.system(size: 14.scaled(by: scale)))
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                        } else {
                            Text("\(powerSourceMonitor.batteryLevel)%")
                                .font(.system(size: 14.scaled(by: scale)))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                    Text("Your Mac is fully charged.")
                        .font(.system(size: 11.scaled(by: scale)))
                        .foregroundStyle(.gray.opacity(0.6))
                        .fontWeight(.medium)
                        .lineLimit(1)
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
                        .padding(.trailing, 10.scaled(by: scale))
                }
                
                Spacer()
            }
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
    }
    
    @ViewBuilder
    private var greenIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30.scaled(by: scale))
                .fill(.green.opacity(0.2))
                .frame(width: 70.scaled(by: scale), height: 40.scaled(by: scale))
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.green.opacity(0.4))
                    .frame(width: 44.scaled(by: scale), height: 24.scaled(by: scale))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4.scaled(by: scale))
                            .fill(Color.green.gradient)
                            .frame(width: 34.scaled(by: scale), height: 14.scaled(by: scale))
                            .opacity(pulse ? 1 : 0.4)
                            .onAppear {
                                startPulse()
                            }
                    )
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.green.opacity(0.4))
                    .frame(width: 3.scaled(by: scale), height: 8.scaled(by: scale))
            }
        }
    }
    
    @ViewBuilder
    private var yellowIndicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30.scaled(by: scale))
                .fill(.yellow.opacity(0.2))
                .frame(width: 70.scaled(by: scale), height: 40.scaled(by: scale))
            
            HStack(spacing: 2.scaled(by: scale)) {
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 44.scaled(by: scale), height: 24.scaled(by: scale))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow.gradient)
                            .frame(width: 34.scaled(by: scale), height: 14.scaled(by: scale))
                            .opacity(pulse ? 1 : 0.4)
                            .onAppear {
                                startPulse()
                            }
                    )
                
                RoundedRectangle(cornerRadius: 10.scaled(by: scale))
                    .fill(.yellow.opacity(0.4))
                    .frame(width: 3.scaled(by: scale), height: 8.scaled(by: scale))
            }
        }
    }
    
    @ViewBuilder
    private var magSafeIndicator: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .frame(width: 40.scaled(by: scale), height: 5.scaled(by: scale))
            
            ZStack {
                RoundedRectangle(cornerRadius: 2.scaled(by: scale))
                    .fill(.gray.opacity(0.2).gradient)
                    .frame(width: 30.scaled(by: scale), height: 40.scaled(by: scale))
                
                Circle()
                    .fill(changeBatteryIndicator ? .orange : .green)
                    .shadow(color: changeBatteryIndicator ? .orange : .green , radius: 5.scaled(by: scale))
                    .frame(width: 5.scaled(by: scale), height: 5.scaled(by: scale))
            }
            
            Rectangle()
                .fill(.white.opacity(0.4))
                .frame(width: 3.scaled(by: scale), height: 32.scaled(by: scale))
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        NotchShape(topCornerRadius: 18, bottomCornerRadius: 36)
            .fill(.black)
            .stroke(.green.opacity(0.3), lineWidth: 2)
            .overlay{ FullPowerNotchView(powerSourceMonitor: PowerSourceMonitor()) }
            .frame(width: 316, height: 108)
        
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .stroke(.red, lineWidth: 1)
            .frame(width: 226, height: 38)
    }
    .frame(width: 400, height: 250, alignment: .top)
}
