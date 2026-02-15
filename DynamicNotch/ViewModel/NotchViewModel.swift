import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var state = NotchState()
    @Published var showNotch = false

    private var temporaryTask: Task<Void, Never>?
    private var isTransitioning = false
    private let hideDelay: TimeInterval = 0.3

    func send(_ intent: NotchIntent) {
        switch intent {
        case .showActive(let content):
            showActive(content)

        case .showTemporary(let content, let duration):
            showTemporary(content, duration: duration)

        case .hideTemporary:
            hideTemporary()
        }
    }
    
    func handleStrokeVisibility(_ newValue: NotchContent) {
        DispatchQueue.main.async {
            if newValue != .none {
                self.showNotch = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if self.state.activeContent == .none && self.state.temporaryContent == nil {
                        self.showNotch = false
                    }
                }
            }
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        switch event {
        case .charger:
            send(.showTemporary(.charger, duration: 4))
            
        case .lowPower:
            send(.showTemporary(.lowPower, duration: 4))
            
        case .fullPower:
            send(.showTemporary(.fullPower, duration: 5))
        }
    }
    
    private func showActive(_ content: NotchContent) {
        guard state.activeContent != content else { return }

        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.4)) {
                    self.state.temporaryContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.activeContent = content
                }
            }
        )
    }
    
    private func showTemporary(_ content: NotchContent, duration: TimeInterval) {
        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.5)) {
                    self.state.temporaryContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.temporaryContent = content
                }

                self.temporaryTask = Task {
                    try? await Task.sleep(
                        nanoseconds: UInt64(duration * 1_000_000_000)
                    )
                    await MainActor.run {
                        self.hideTemporary()
                    }
                }
            }
        )
    }

    private func hideTemporary() {
        cancelTemporary()
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.5)) {
                self.state.temporaryContent = nil
            }
        }
    }

    private func transition(hide: @escaping () -> Void, show: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true

        DispatchQueue.main.async {
            hide()

            DispatchQueue.main.asyncAfter(deadline: .now() + self.hideDelay) {
                show()
                self.isTransitioning = false
            }
        }
    }

    private func cancelTemporary() {
        temporaryTask?.cancel()
        temporaryTask = nil
    }
}
