import SwiftUI
import Combine

struct NotchView: View {
    @StateObject private var notchViewModel = NotchViewModel()
    @StateObject private var powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    
    @State private var isPressed = false
    @State private var showStroke = false
    
    weak var window: NSWindow?
    
    var body: some View {
        VStack {
            ZStack {
                NotchShape(topCornerRadius: notchViewModel.state.cornerRadius.top, bottomCornerRadius: notchViewModel.state.cornerRadius.bottom)
                    .fill(Color.clear)
                    .stroke(showStroke ? Color.white.opacity(0.1) : Color.clear, lineWidth: 3)
                    .animation(.spring(duration: 0.6), value: showStroke)
                
                NotchShape(topCornerRadius: notchViewModel.state.cornerRadius.top, bottomCornerRadius: notchViewModel.state.cornerRadius.bottom)
                    .fill(Color.black)
                    .overlay {
                        if notchViewModel.state.content != .none {
                            NotchContant(notchViewModel: notchViewModel, powerViewModel: powerViewModel)
                                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .scale).combined(with: .offset(x: 0, y: -10)))
                        }
                    }
            }
            .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
            .scaleEffect(isPressed ? 1.04 : 1.0, anchor: .top)
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isPressed)
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
            )
            .onChange(of: notchViewModel.state.content) { _, newValue in
                if newValue != .none {
                    showStroke = true
                }
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showStroke = false
                    }
                }
            }
            .onReceive(powerViewModel.$event.compactMap { $0 }) { event in
                switch event {
                case .charger:
                    notchViewModel.send(.showTemporary(.charger, duration: 4))
                    
                case .lowPower:
                    notchViewModel.send(.showTemporary(.lowPower, duration: 4))
                    
                case .fullPower:
                    notchViewModel.send(.showTemporary(.fullPower, duration: 5))
                }
            }
            
            Spacer()
            
            Controller(notchViewModel: notchViewModel)
                .background(.gray.opacity(0.3))
                .padding(.bottom, 50)
        }
        .onHover { hovering in window?.ignoresMouseEvents = !hovering }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NotchView()
        .frame(width: 500, height: 400)
}
