import SwiftUI

struct ContentView: View {
    @State private var isHoveredScaleEffect: Bool = false
    @State private var isOpenNotch: Bool = false
    @State private var isDragging: Bool = false
    @State private var clickMonitor = GlobalClickMonitor()
    
    var body: some View {
        ZStack {
            background
                .overlay {
                    if isOpenNotch {
                        notchContent
                    }
                }
            
        }
        .frame(width: 500, height: 300, alignment: .top)
    }
    
    @ViewBuilder
    private var background: some View {
        NotchShape(topCornerRadius: isOpenNotch ? 18 : 8, bottomCornerRadius: isOpenNotch ? 28 : 13)
            .fill(Color.black)
            .stroke(.black, lineWidth: 1)
            .shadow(color: .black.opacity(0.4), radius: isOpenNotch ? 10 : 0)
            .frame(
                width: isOpenNotch ? 330 : (isHoveredScaleEffect ? 226 : 207),
                height: isOpenNotch ? 180 : 38
            )
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.interactiveSpring(duration: 0.4)) {
                        isDragging = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.interactiveSpring(duration: 0.5)) {
                        isDragging = false
                        isOpenNotch = true
                    }
                }
            )
            .onHover { hover in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    isHoveredScaleEffect = hover
                }
            }
            .onAppear { clickMonitor.start {
                withAnimation(.interactiveSpring(duration: 0.5)) {
                    isOpenNotch = false
                }
            }}
            .onDisappear { clickMonitor.stop() }
    }
    
    @ViewBuilder
    private var notchContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hello, World!")
                .font(.title)
                .bold()
            Text("This is a sample app to demonstrate the use of SwiftUI with the Notch.swift library.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {}) {
                Text("")
            }
        }
        .transition(.blurAndFade.combined(with: .scale(scale: 0.5, anchor: .top)))
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .padding()
    }
}

#Preview {
    ContentView()
        .frame(width: 500, height: 299)
}

