import SwiftUI

struct ContentView: View {
    @State private var isHoveredScaleEffect: Bool = false
    @State private var isOpenNotch: Bool = false
    @State private var isDragging: Bool = false
    @State private var clickMonitor = GlobalClickMonitor()
    
    var body: some View {
        ZStack {
            NotchShape(bottomCornerRadius: isOpenNotch ? 26 : 13, topCornerRadius: isOpenNotch ? 14 : 8)
                .fill(Color.black)
                .stroke(.black, lineWidth: 1)
                .shadow(color: .black, radius: isOpenNotch ? 10 : 0)
                .frame(
                    width: isOpenNotch ? 330 : (isHoveredScaleEffect ? 226 : 207),
                    height: isOpenNotch ? 180 : 38
                )
               
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .onHover { hover in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        isHoveredScaleEffect = hover
                    }
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.bouncy(duration: 0.4)) {
                            isDragging = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.bouncy(duration: 0.5)) {
                            isDragging = false
                            isOpenNotch = true
                        }
                    }
                )
        }
        .frame(width: 500, height: 300, alignment: .top)
        .onAppear { clickMonitor.start {
            withAnimation(.bouncy(duration: 0.5)) {
                isOpenNotch = false
            }
        }}
        .onDisappear { clickMonitor.stop() }
    }
}

#Preview {
    ContentView()
        .frame(width: 500, height: 299)
}

