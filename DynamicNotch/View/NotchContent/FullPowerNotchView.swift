import SwiftUI

struct FullPowerNotchContent: NotchContentProvider {
    let id = "battery.fullPower"
    let powerMonitor: PowerSourceMonitor
    
    var strokeColor: Color { .green.opacity(0.3) }
    var offsetYTransition: CGFloat { -60 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 80, height: baseHeight + 70)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 18, bottom: 36)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(FullPowerNotchView(powerSourceMonitor: powerMonitor))
    }
}

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
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    title
                    description
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
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
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
    var title: some View {
        HStack {
            Text("Full Battery")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if powerSourceMonitor.isLowPowerMode {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 13))
                    .fontWeight(.semibold)
                    .foregroundStyle(.yellow)
            } else {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 13))
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
        }
    }
    
    @ViewBuilder
    var description: some View {
        Text("Your Mac is fully charged.")
            .font(.system(size: 10))
            .foregroundStyle(.gray.opacity(0.6))
            .fontWeight(.medium)
            .lineLimit(1)
    }
    
    @ViewBuilder
    var greenIndicator: some View {
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
    var yellowIndicator: some View {
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
    var magSafeIndicator: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .frame(width: 30, height: 5)
            
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
