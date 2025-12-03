import SwiftUI

struct NotchContentView: View {
    @StateObject private var layout = NotchLayoutViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var clickMonitor = GlobalClickMonitor()
    
    var body: some View {
        ZStack(alignment: .top) {
            NotchContainer(kind: .player) { PlayerView() }
        }
        .frame(width: 500, height: 300, alignment: .top)
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
                withAnimation(.snappy(duration: 0.2)) { layout.dragScale = 1.05 }
            }
            .onEnded { _ in
                withAnimation(.snappy(duration: 0.4)) {
                    layout.dragScale = 1.0
                    layout.state = .expanded
                }
            }
        )
        .environmentObject(layout)
        .environmentObject(playerViewModel)
    }
}

#Preview {
    NotchContentView()
        .frame(width: 500, height: 300)
}
