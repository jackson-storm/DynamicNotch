import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var screenCapture: ScreenCaptureManager
    @EnvironmentObject var windowModel: WindowModel
    
    @State private var displayedColor: Color = .black
    @State private var lastNSColor: NSColor = .black
    
    @State private var scale: Bool = false
    
    var body: some View {
        ZStack {
            NotchBorderWithoutTop(topCornerRadius: 9, bottomCornerRadius: 13)
                .stroke(displayedColor, lineWidth: 4)
                .frame(width: 324, height: 38)
            
            NotchShape(topCornerRadius: 9, bottomCornerRadius: 13)
                .fill(.black)
                .stroke(.black, lineWidth: 1)
                .frame(width: 324, height: 38)
        }
        .scaleEffect(scale ? 1.05 : 1.0, anchor: .top)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !scale {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            scale = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        scale = false
                    }
                }
        )
        .frame(width: 420, height: 140, alignment: .top)
        .onReceive(screenCapture.$lastFrame) { frame in
            guard let frame = frame else { return }
            let winFrame = windowModel.windowFrame
            guard winFrame.width > 0 && winFrame.height > 0 else { return }
            
            guard let screen = NSScreen.main else { return }
            let screenHeight = screen.frame.height
            
            let correctedRect = CGRect(
                x: winFrame.origin.x,
                y: screenHeight - winFrame.origin.y - winFrame.height,
                width: winFrame.width,
                height: winFrame.height
            )
            
            let imageRect = CGRect(origin: .zero, size: CGSize(width: frame.width, height: frame.height))
            guard let intersect = correctedRect.intersection(imageRect).isNull ? nil : correctedRect.intersection(imageRect) else { return }
            guard intersect.width >= 2 && intersect.height >= 2 else { return }
            
            guard let cropped = frame.cropping(to: intersect) else { return }
            if let nsColor = cropped.averageColor() {
                DispatchQueue.main.async {
                    self.lastNSColor = nsColor
                    withAnimation(.linear(duration: 0.18)) {
                        self.displayedColor = Color(nsColor)
                    }
                    windowModel.borderColor = nsColor
                }
            }
        }
        .onReceive(windowModel.$borderColor) { nsColor in
            withAnimation(.linear(duration: 0.18)) {
                self.displayedColor = Color(nsColor)
            }
        }
    }
}
