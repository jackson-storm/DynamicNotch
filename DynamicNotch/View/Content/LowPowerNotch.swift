import SwiftUI

struct LowPowerNotch: View {
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
                    Text("Battery Low")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                    
                    Text("\(powerSourceMonitor.batteryLevel)%")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                Text("Turn on Low Power Mode or put it on charge.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray.opacity(0.6))
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            indicator
        }
        .padding(.horizontal, 35)
        .padding(.top, 30)
    }
    
    private var indicator: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.red.opacity(0.2))
                .frame(width: 80, height: 50)
            
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.5))
                    .frame(width: 44, height: 24)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.5))
                    .frame(width: 3, height: 8)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.gradient)
                .frame(width: 8, height: 14)
                .opacity(pulse ? 1 : 0.3)
                .offset(x: -15)
                .onAppear {
                    startPulse()
                }
            
            RoundedRectangle(cornerRadius: 30)
                .stroke(.red.opacity(0.9).gradient, lineWidth: 1.5)
                .frame(width: pulse ? 8 : 30, height: pulse ? 14 : 32)
                .offset(x: -15)
                .opacity(pulse ? 0.3 : 1)
        }
    }
}

#Preview {
    ZStack {
        LowPowerNotch(powerSourceMonitor: PowerSourceMonitor())
            .frame(width: 360 ,height: 110)
            .background(
                NotchShape(topCornerRadius: 18, bottomCornerRadius: 36)
                    .fill(.black)
            )
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .fill(.black)
            .stroke(.red.opacity(0.3), lineWidth: 1)
            .frame(width: 226, height: 38)
            .padding(.bottom, 72)
    }
    .frame(width: 400, height: 200)
}
