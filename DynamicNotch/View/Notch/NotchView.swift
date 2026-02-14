import SwiftUI
import Combine
import AppKit

struct NotchView: View {
    @StateObject private var notchViewModel = NotchViewModel()
    @StateObject private var powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    @Environment(\.openWindow) private var openWindow
    
    @State private var isPressed = false
    @State private var showStroke = false
    
    weak var window: NSWindow?
    
    var body: some View {
        VStack {
            notchBody
                .notchPressable(isPressed: $isPressed)
                .onChange(of: notchViewModel.state.content, perform: handleStrokeVisibility)
                .onReceive(powerViewModel.$event.compactMap { $0 }, perform: handlePowerEvent)
        }
        .windowHover(window)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, -0.3)
    }
}

private extension NotchView {
    var notchBody: some View {
        ZStack {
            NotchShape(
                topCornerRadius: notchViewModel.state.cornerRadius.top,
                bottomCornerRadius: notchViewModel.state.cornerRadius.bottom
            )
            .stroke(showStroke ? Color.white.opacity(0.1) : .clear, lineWidth: 3)
            .animation(.spring(duration: 0.6), value: showStroke)
            
            NotchShape(
                topCornerRadius: notchViewModel.state.cornerRadius.top,
                bottomCornerRadius: notchViewModel.state.cornerRadius.bottom
            )
            .fill(Color.black)
            .overlay { contentOverlay }
        }
        .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
        .contextMenu { contextMenuItem }
    }
    
    @ViewBuilder
    var contentOverlay: some View {
        if notchViewModel.state.content != .none {
            NotchContentView(
                notchViewModel: notchViewModel,
                powerViewModel: powerViewModel
            )
            .transition(
                .blurAndFade
                    .animation(.spring(duration: 0.5))
                    .combined(with: .scale)
                    .combined(with: .offset(
                        x: notchViewModel.state.offsetXTransition,
                        y: notchViewModel.state.offsetYTransition
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    var contextMenuItem: some View {
        Menu("Show Temporary") {
            Button("Charger (4s)") {
                notchViewModel.send(.showTemporary(.charger, duration: 4))
            }
            Button("Low Power (4s)") {
                notchViewModel.send(.showTemporary(.lowPower, duration: 4))
            }
            Button("Full Power (5s)") {
                notchViewModel.send(.showTemporary(.fullPower, duration: 5))
            }
            Button("Hide Temporary") {
                notchViewModel.send(.hideTemporary)
            }
        }
        Divider()
        
        Button("Settings") {
            openWindow(id: "settings")
        }
        
        Divider()
        
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}

private extension NotchView {
    func handleStrokeVisibility(_ newValue: NotchContent) {
        if newValue != .none {
            showStroke = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showStroke = false
            }
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        switch event {
        case .charger:
            notchViewModel.send(.showTemporary(.charger, duration: 4))
            
        case .lowPower:
            notchViewModel.send(.showTemporary(.lowPower, duration: 4))
            
        case .fullPower:
            notchViewModel.send(.showTemporary(.fullPower, duration: 5))
        }
    }
}

#Preview {
    NotchView()
        .frame(width: 500, height: 400)
}
