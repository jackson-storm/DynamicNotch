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
            
            if bluetoothViewModel.isConnected, let level = bluetoothViewModel.batteryLevel {
                HStack(spacing: 6) {
                    Text("\(level)%")
                        .foregroundStyle(color(for: level).gradient)
                    
                    Image(systemName: "airpods.max")
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(color(for: level).gradient)
                }
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
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
