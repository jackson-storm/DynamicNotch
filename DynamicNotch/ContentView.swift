import SwiftUI

struct NotchShape: Shape {
    var bottomCornerRadius: CGFloat = 14

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
    @State private var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            NotchShape()
                .fill(Color.black)
                .frame(width: isHovered ?  228 : 208, height: isHovered ? 48 : 38)
        }
        .animation(.bouncy(duration: 0.25), value: isHovered)
        .onHover{ isHover in
            isHovered = isHover
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 300, height: 200)
}
