import SwiftUI

struct NotchShape: Shape {
    var bottomCornerRadius: CGFloat
    var topCornerRadius: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bottomCornerRadius, topCornerRadius) }
        set {
            bottomCornerRadius = newValue.first
            topCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let rBottom = min(bottomCornerRadius, min(w, h) / 2)
        let rTop = min(topCornerRadius, min(w, h) / 2)

        let k: CGFloat = rTop * 1.2

        var path = Path()

        path.move(to: CGPoint(x: rTop, y: 0))

        path.addCurve(
            to: CGPoint(x: 0, y: rTop),
            control1: CGPoint(x: -k * 4.0, y: 0),
            control2: CGPoint(x: 0, y: -k * 0.9)
        )
        
        path.addLine(to: CGPoint(x: 0, y: h - rBottom))

        path.addQuadCurve(
            to: CGPoint(x: rBottom, y: h),
            control: CGPoint(x: 0, y: h)
        )

        path.addLine(to: CGPoint(x: w - rBottom, y: h))
        
        path.addQuadCurve(
            to: CGPoint(x: w, y: h - rBottom),
            control: CGPoint(x: w, y: h)
        )
        path.addLine(to: CGPoint(x: w, y: rTop))
        
        path.addCurve(
            to: CGPoint(x: w - rTop, y: 0),
            control1: CGPoint(x: w, y: -k * 0.9),
            control2: CGPoint(x: w + k * 4.0, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    ContentView()
        .frame(width: 500, height: 350)
}
