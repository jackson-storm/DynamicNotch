import SwiftUI

struct BluetoothConnectedNotchContent: NotchContentProtocol {
    let id = "bluetooth.connected"
    let bluetoothViewModel: BluetoothViewModel
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = bluetoothViewModel.isShowingBluetoothDetail ? 175 : 210
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(BluetoothConnectedNotchView(bluetoothViewModel: bluetoothViewModel))
    }
}

private struct BluetoothConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    
    private func color(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            leftContent
            Spacer()
            rightContent
        }
        .padding(.horizontal, 14.scaled(by: scale))
        .font(.system(size: 14))
        .onAppear {
            bluetoothViewModel.isShowingBluetoothDetail = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(duration: 0.4)) {
                    bluetoothViewModel.isShowingBluetoothDetail = true
                }
            }
        }
        .onDisappear {
            bluetoothViewModel.isShowingBluetoothDetail = false
        }
    }
    
    @ViewBuilder
    private var leftContent: some View {
        if !bluetoothViewModel.isShowingBluetoothDetail {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue)
                        .frame(width: 22, height: 22)
                    
                    Image("bluetooth")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text(verbatim: "Bluetooth")
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)))
            
        } else {
            if bluetoothViewModel.isShowingBluetoothDetail {
                MarqueeText(
                    $bluetoothViewModel.deviceName,
                    font: .system(size: 14),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 0.5,
                    frameWidth: 90
                )
                .lineLimit(1)
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .trailing)))
            }
        }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        if !bluetoothViewModel.isShowingBluetoothDetail {
            Text(verbatim: "Connected")
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            
        } else {
            HStack(spacing: 6) {
                if let level = bluetoothViewModel.batteryLevel {
                    Text("\(level)%")
                        .foregroundStyle(color(for: level).gradient)
                } else {
                    Text("---")
                        .foregroundStyle(.white.opacity(0.6))
                }
                Image(systemName: bluetoothViewModel.deviceType.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))
        }
    }
}
