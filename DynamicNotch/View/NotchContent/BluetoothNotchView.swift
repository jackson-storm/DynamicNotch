import SwiftUI

struct BluetoothNotchView: View {
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
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 60)))
                .lineLimit(1)
                
            } else {
                Text("Connected")
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 60)))
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
        .padding(.horizontal, 3)
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

private struct BluetoothNotchMock: View {
    @State private var isSecondText = false
    @State private var deviceName: String = "Honor Airbuds 2 lite"
    
    let deviceType: BluetoothDeviceType
    let batteryLevel: Int?
    let isConnected: Bool
    
    private func color(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            if isSecondText {
                MarqueeText(
                    $deviceName,
                    font: .system(size: 14),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 0.5,
                    frameWidth: 75
                )
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 60)))
                .lineLimit(1)
                
            } else {
                Text("Connected")
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 60)))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                if let level = batteryLevel {
                    Text("\(level)%")
                        .foregroundStyle(color(for: level).gradient)
                } else {
                    Text("---")
                        .foregroundStyle(.white.opacity(0.6))
                }
                Image(systemName: deviceType.symbolName)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 20)
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

#Preview {
    let types: [BluetoothDeviceType] = [
        .keyboard, .headphones, .phone, .computer, .speaker, .mouse, .headset, .combo, .unknown
    ]
    let levels: [Int?] = [100, 55, 12, 80, 45, 37, 8, 68, nil]
    
    ScrollView {
        VStack(spacing: 14) {
            ForEach(Array(types.enumerated()), id: \.offset) { index, type in
                Group {
                    BluetoothNotchMock(deviceType: type, batteryLevel: levels[index],isConnected: true)
                        .frame(width: 400, height: 38)
                        .background(
                            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                                .fill(.black)
                        )
                        .overlay(
                            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                                .stroke(.red.opacity(0.5), lineWidth: 1)
                                .frame(width: 226, height: 38)
                        )
                }
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.24))
    }
    .frame(width: 450, height: 650, alignment: .top)
}

