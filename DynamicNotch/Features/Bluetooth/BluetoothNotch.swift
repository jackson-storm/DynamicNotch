import SwiftUI

struct BluetoothConnectedNotchContent: NotchContentProtocol {
    let id = "bluetooth.connected"
    let bluetoothViewModel: BluetoothViewModel
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(BluetoothConnectedNotchView(bluetoothViewModel: bluetoothViewModel))
    }
}

struct BluetoothDisconnectedNotchContent: NotchContentProtocol {
    let id = "bluetooth.disconnected"
    
    var strokeColor: Color { .red.opacity(0.3) }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 240, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(BluetoothDisconnectedNotchView())
    }
}

private struct BluetoothConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @State private var isSecondText = false
    
    private func color(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            if isSecondText {
                MarqueeText(
                    $bluetoothViewModel.deviceName,
                    font: .system(size: 14),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 0.5,
                    frameWidth: 75
                )
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))
                .lineLimit(1)
                
            } else {
                Text("Connected")
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if bluetoothViewModel.isConnected {
                HStack(spacing: 6) {
                    if let level = bluetoothViewModel.batteryLevel {
                        Text("\(level)%")
                            .foregroundStyle(color(for: level).gradient)
                    } else {
                        Text("---")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Image(systemName: bluetoothViewModel.deviceType.symbolName)
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16.scaled(by: scale))
        .font(.system(size: 14))
        .onAppear {
            if !isSecondText {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(duration: 0.4)) {
                        isSecondText = true
                    }
                }
            }
        }
    }
}

private struct BluetoothDisconnectedNotchView: View {
    @Environment(\.notchScale) var scale
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 34, height: 22)
                    
                    Image("bluetooth.slash")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("Bluetooth")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            
            Text("Disconnected")
                .font(.system(size: 14))
                .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.horizontal, 15.scaled(by: scale))
    }
}
