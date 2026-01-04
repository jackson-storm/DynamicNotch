import SwiftUI

struct ChargerNotch: View {
    @ObservedObject var powerSourceMonitor: PowerSourceMonitor
    
    var body: some View {
        HStack {
            Text("Charging").font(.system(size: 14))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(powerSourceMonitor.batteryLevel)%")
                    .font(.system(size: 14))
                    .foregroundStyle(.green.gradient)
                
                HStack(spacing: 1.5) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.green.opacity(0.5))
                        
                        GeometryReader { geo in
                            let clamped = max(0, min(powerSourceMonitor.batteryLevel, 100))
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
                        .fill(powerSourceMonitor.batteryLevel == 100 ? Color.green : Color.green.opacity(0.5))
                        .frame(width: 2, height: 6)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func measureSize(_ callback: @escaping (CGSize) -> Void) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: callback)
    }
}
