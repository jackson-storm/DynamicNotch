import SwiftUI

struct AudioHardwareNotch: View {
    private func color(for level: Int) -> Color {
        switch level {
        case 0..<20: return .red
        case 20..<50: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        HStack {
            Text("Connected")
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(70)%")
                
                Image(systemName: "airpods.max")
                    .font(.system(size: 18))
                    .bold()
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        AudioHardwareNotch()
            .frame(width: 405, height: 38)
            .background(
                NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                    .fill(.black)
            )
    }
    .frame(width: 450, height: 100)
}
