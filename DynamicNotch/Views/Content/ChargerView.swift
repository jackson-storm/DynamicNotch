import SwiftUI

struct ChargerNotch: View {
    @ObservedObject var powerSourceMonitor: PowerSourceMonitor
    
    var level: Int
    var isCharging: Bool
    
    var body: some View {
        HStack {
            Text("Charging").font(.system(size: 14))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(level)%")
                    .font(.system(size: 14))
                    .foregroundStyle(.green.gradient)
                
                HStack(spacing: 1.5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.green.opacity(0.5))
                        
                        GeometryReader { geo in
                            let clamped = max(0, min(level, 100))
                            let fraction = CGFloat(clamped) / 100
                            let width = fraction * geo.size.width
                            
                            Rectangle()
                                .fill(.green.gradient)
                                .frame(width: max(0, width))
                        }
                    }
                    .frame(width: 28, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(level == 100 ? Color.green : Color.green.opacity(0.5))
                        .frame(width: 2, height: 6)
                }
            }

        }
        .padding(.horizontal, 20)
    }
}
