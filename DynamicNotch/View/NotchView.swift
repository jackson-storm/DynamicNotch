import SwiftUI
import Combine

struct NotchView: View {
    @StateObject private var notchViewModel = NotchViewModel()
    @StateObject private var powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    
    weak var window: NSWindow?
    
    var body: some View {
        VStack {
            ZStack {
                NotchShape(topCornerRadius: notchViewModel.state.cornerRadius.top,
                           bottomCornerRadius: notchViewModel.state.cornerRadius.bottom)
                .fill(Color.black)
                
                content
            }
            .frame(width: notchViewModel.state.size.width,
                   height: notchViewModel.state.size.height)
            
            controls
        }
        .onHover { hovering in
            window?.ignoresMouseEvents = !hovering
        }
        .onReceive(powerViewModel.$shouldShowCharger) { show in
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
            if show {
                notchViewModel.send(.show(.lowPower))
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if notchViewModel.state.content == .lowPower {
                        notchViewModel.send(.hide)
                    }
                }
                
            } else if notchViewModel.state.content == .lowPower {
                notchViewModel.send(.hide)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private extension NotchView {
    @ViewBuilder
    var content: some View {
        Group {
            switch notchViewModel.state.content {
            case .none:
                EmptyView()
                
            case .music:
                PlayerNotch()
                
            case .notification:
                Text("Notification")
                
            case .charger:
                ChargerNotch(powerSourceMonitor: powerViewModel.powerMonitor)
                
            case .lowPower:
                LowPower(powerSourceMonitor: powerViewModel.powerMonitor)
            }
        }
        .id(notchViewModel.state.content)
        .transition(.blurAndFade.animation(.spring(duration: 0.5)).combined(with: .scale))
    }
    
    var controls: some View {
        HStack(spacing: 15) {
            Button("Music") {
                notchViewModel.send(.show(.music))
            }
            Button("Charger") {
                notchViewModel.send(.show(.charger))
            }
            Button("Low Power") {
                notchViewModel.send(.show(.lowPower))
            }
            Button("Notification") {
                notchViewModel.send(.show(.notification))
            }
            Button("Hide") {
                notchViewModel.send(.hide)
            }
        }
        .padding()
    }
}
