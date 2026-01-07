import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var state = NotchState()

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.state.activeContent = content
                    }
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

        withAnimation(.spring(response: 0.5)) {
            state.temporaryContent = nil
        }
    }

    private func transition(hide: @escaping () -> Void, show: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true

        hide()

        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay) {
            show()
            self.isTransitioning = false
        }
    }

    private func cancelTemporary() {
        temporaryTask?.cancel()
        temporaryTask = nil
    }
}
