import SwiftUI

struct NotchContainer<Content: View>: View {
    @EnvironmentObject var layout: NotchLayoutViewModel
    @ViewBuilder var content: () -> Content
    @State private var clickMonitor = GlobalClickMonitor()
    
    let kind: NotchContentKind
    
    init(kind: NotchContentKind, @ViewBuilder content: @escaping () -> Content) {
        self.kind = kind
        self.content = content
    }
    
    var body: some View {
        let size = layout.size(for: kind)
        
        NotchShape(topCornerRadius: size.topCornerRadius, bottomCornerRadius: size.bottomCornerRadius)
            .fill(Color.black)
            .stroke(.black, lineWidth: 1)
            .frame(width: size.width, height: size.height)
            .overlay(content())
            .onAppear { clickMonitor.start {
                withAnimation(.snappy(duration: 0.5)) {
                    layout.state = .compact
                }
            }}
            .onHover { hover in
                withAnimation(.snappy(duration: 0.4)) {
                    if layout.state == .expanded { return }
                }
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.snappy(duration: 0.2)) {}
                }
                .onEnded { _ in
                    withAnimation(.snappy(duration: 0.4)) {
                        layout.state = .expanded
                    }
                }
            )
    }
}
