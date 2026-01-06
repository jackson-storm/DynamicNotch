import SwiftUI
import Combine

struct NotchView: View {
    @StateObject private var notchViewModel = NotchViewModel()
    @StateObject private var powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    @State private var isPressed = false
    
    weak var window: NSWindow?
    
    var body: some View {
        VStack {
            ZStack {
                NotchShape(topCornerRadius: notchViewModel.state.cornerRadius.top, bottomCornerRadius: notchViewModel.state.cornerRadius.bottom)
                    .fill(Color.clear)
                    .stroke((notchViewModel.state.content == .none) ? .clear : .white.opacity(0.1), lineWidth: 3)
                    
                NotchShape(topCornerRadius: notchViewModel.state.cornerRadius.top, bottomCornerRadius: notchViewModel.state.cornerRadius.bottom)
                    .fill(Color.black)
                
                NotchContant(notchViewModel: notchViewModel, powerViewModel: powerViewModel)
                    .transition(.blurAndFade.animation(.spring(duration: 0.5)).combined(with: .scale))
            }
            .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
            .scaleEffect(isPressed ? 1.04 : 1.0, anchor: .top)
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isPressed)
            .onReceive(powerViewModel.$shouldShowCharger) { show in
                guard powerViewModel.isInitialized else { return }
                if show {
                    notchViewModel.send(.show(.charger))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if notchViewModel.state.content == .charger {
                            notchViewModel.send(.hide)
                        }
                    }
                } else if notchViewModel.state.content == .charger {
                    notchViewModel.send(.hide)
                }
            }
            .onReceive(powerViewModel.$isBatteryLevel20PercentOrLower) { show in
                guard powerViewModel.isInitialized else { return }
                if show {
                    notchViewModel.send(.show(.lowPower))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        if notchViewModel.state.content == .lowPower {
                            notchViewModel.send(.hide)
                        }
                    }
                } else if notchViewModel.state.content == .lowPower {
                    notchViewModel.send(.hide)
                }
            }
            .onReceive(powerViewModel.$isBatteryLevel100Percent) { show in
                guard powerViewModel.isInitialized else { return }
                if show {
                    notchViewModel.send(.show(.fullPower))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        if notchViewModel.state.content == .fullPower {
                            notchViewModel.send(.hide)
                        }
                    }
                } else if notchViewModel.state.content == .fullPower {
                    notchViewModel.send(.hide)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !isPressed { isPressed = true } }
                    .onEnded { _ in isPressed = false }
            )
            Spacer()
            
            Controller(notchViewModel: notchViewModel)
                .background(.gray.opacity(0.3))
                .padding(.bottom, 50)
        }
        .onHover { hovering in
            window?.ignoresMouseEvents = !hovering
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NotchView()
}
