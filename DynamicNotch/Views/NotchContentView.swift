import SwiftUI

enum Submissions {
    case player
}

struct NotchContentView: View {
    @State private var isHoveredScaleEffect: Bool = false
    @State private var isOpenNotch: Bool = false
    @State private var isDragging: Bool = false
    @State private var clickMonitor = GlobalClickMonitor()
    
    var originalWidth: CGFloat = 224
    var originalHeitht: CGFloat = 38
    
    var isOpenNotchWidth: CGFloat = 440
    var isOpenNotchHeight: CGFloat = 200
    
    var isHoveredScaleEffectWidth: CGFloat { originalWidth + 20 }
    
    var body: some View {
        ZStack {
            background
                .overlay {
                    if isOpenNotch {
                        PlayerView(isDragging: $isDragging)
                    }
                }
            
        }
        .frame(width: 500, height: 300, alignment: .top)
    }
    
    @ViewBuilder
    private var background: some View {
        NotchShape(topCornerRadius: isOpenNotch ? 28 : 9, bottomCornerRadius: isOpenNotch ? 38 : 13)
            .fill(Color.black)
            .stroke(.black, lineWidth: 1)
            .shadow(color: .black.opacity(0.6), radius: isOpenNotch ? 10 : 0)
            .frame(
                width: isOpenNotch ? isOpenNotchWidth : (isHoveredScaleEffect ? isHoveredScaleEffectWidth : originalWidth),
                height: isOpenNotch ? isOpenNotchHeight : originalHeitht
            )
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.snappy(duration: 0.4)) {
                        isDragging = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.snappy(duration: 0.4)) {
                        isDragging = false
                        isOpenNotch = true
                    }
                }
            )
            .onHover { hover in
                withAnimation(.snappy(duration: 0.4)) {
                    isHoveredScaleEffect = hover
                }
            }
            .onAppear { clickMonitor.start {
                withAnimation(.snappy(duration: 0.5)) {
                    isOpenNotch = false
                }
            }}
            .onDisappear { clickMonitor.stop() }
    }
}

#Preview {
    NotchContentView()
        .frame(width: 500, height: 299)
}
