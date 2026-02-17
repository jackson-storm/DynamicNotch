import SwiftUI

struct BluetoothNotch: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    
    private func color(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    var body: some View {
        HStack {
            Text("Connected")
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            
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
    }
}

#Preview {
    ZStack(alignment: .top) {
        BluetoothNotch(bluetoothViewModel: BluetoothViewModel())
            .frame(width: 400, height: 38)
            .background(
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
            )
        NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
            .stroke(.red, lineWidth: 1)
            .frame(width: 226, height: 38)
    }
    .frame(width: 450, height: 100, alignment: .top)
}
