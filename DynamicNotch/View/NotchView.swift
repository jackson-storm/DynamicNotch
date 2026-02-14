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
            notchBody
                .notchPressable(isPressed: $isPressed)
                .onChange(of: notchViewModel.state.content, perform: handleStrokeVisibility)
                .onReceive(powerViewModel.$event.compactMap { $0 }, perform: handlePowerEvent)
        }
        .windowHover(window)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            .overlay {contentOverlay}
        }
        .frame(width: notchViewModel.state.size.width, height: notchViewModel.state.size.height)
    }

    @ViewBuilder
    var contentOverlay: some View {
        if notchViewModel.state.content != .none {
            NotchContant(
                notchViewModel: notchViewModel,
                powerViewModel: powerViewModel
            )
            .transition(
                .blurAndFade
                    .animation(.spring(duration: 0.4))
                    .combined(with: .scale)
                    .combined(with: .offset(x: 0, y: -10))
            )
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
