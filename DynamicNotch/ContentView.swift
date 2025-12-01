import SwiftUI

struct NotchShape: Shape {
    var bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = min(bottomCornerRadius, min(w, h) / 2)

        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - r))
        path.addQuadCurve(to: CGPoint(x: w - r, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: r, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - r), control: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        
        return path
    }
}

struct ContentView: View {
    @State private var isHoveredScaleEffect: Bool = false
    @State private var isGestureOpenNotch: Bool = false
    
    @State private var clickMonitor = GlobalClickMonitor()
    
    var body: some View {
        ZStack {
            NotchShape(bottomCornerRadius: isGestureOpenNotch ? 26 : 13)
                .fill(Color.black)
                .stroke(.black, lineWidth: 1)
                .frame(
                    width: isGestureOpenNotch ? 320 : (isHoveredScaleEffect ? 224 : 206),
                    height: isGestureOpenNotch ? 80 : 37
                )
                .onHover { hover in isHoveredScaleEffect = hover }
                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in isGestureOpenNotch = true })
        }
        .animation(.bouncy(duration: 0.3), value: isHoveredScaleEffect)
        .animation(.bouncy(duration: 0.3), value: isGestureOpenNotch)
        .frame(width: 500, height: 200, alignment: .top)
        .onAppear { clickMonitor.start { isGestureOpenNotch = false }}
        .onDisappear { clickMonitor.stop() }
    }
}

#Preview {
    ContentView()
        .frame(width: 500, height: 200)
}
