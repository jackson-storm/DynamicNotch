import SwiftUI

struct BluetoothNotch: View {
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
                    text: bluetoothViewModel.deviceName,
                    font: .system(size: 14, weight: .regular),
                    textColor: .white.opacity(0.8),
                    containerWidth: 80
                )
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 30)))
                .lineLimit(1)
            } else {
                Text("Connected")
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 30)))
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

private struct BluetoothNotchMock: View {
    @State private var isSecondText = false

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
                    text: "Honor Airbuds 2 lite",
                    font: .system(size: 14, weight: .regular),
                    textColor: .white.opacity(0.8),
                    containerWidth: 80
                )
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 30)))
                .lineLimit(1)
                .frame(width: 80)
                .border(.green)
                
            } else {
                Text("Connected")
                    .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .offset(x: 30)))
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

import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    let textColor: Color
    let containerWidth: CGFloat
    let speed: Double = 40
    
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            if textWidth > containerWidth {
                HStack(spacing: 40) {
                    textView
                    textView
                }
                .offset(x: offset)
            } else {
                textView
            }
        }
        .frame(width: containerWidth, height: 20)
        .clipped()
        .onChange(of: textWidth) { _, newValue in
            startIfNeeded()
        }
    }
    
    private var textView: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            textWidth = geo.size.width
                        }
                }
            )
    }
    
    private func startIfNeeded() {
        guard textWidth > containerWidth else { return }
        
        let distance = textWidth + 40
        let duration = distance / speed
        
        offset = 0
        
        DispatchQueue.main.async {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -distance
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
                                .stroke(.red, lineWidth: 1)
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

