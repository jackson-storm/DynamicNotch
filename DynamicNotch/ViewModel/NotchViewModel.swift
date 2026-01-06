import SwiftUI
import Combine

final class NotchViewModel: ObservableObject {
    @Published private(set) var state = NotchState()

    private var isTransitioning = false

    func send(_ intent: NotchIntent) {
        switch intent {
        case .show(let content):
            show(content)
        case .hide:
            hide()
        }
    }

    private func show(_ content: NotchContent) {
        guard state.content != content, !isTransitioning else { return }
        isTransitioning = true

        if state.content != .none {
            hide {
                self.animate {
                    self.state.content = content
                }
                self.finishTransition(after: 0.3)
            }
        } else {
            animate {
                self.state.content = content
            }
            finishTransition(after: 0.3)
        }
    }

    private func hide(completion: (() -> Void)? = nil) {
        withAnimation(.spring(response: 0.5)) {
            self.state.content = .none
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion?()
        }
    }

    private func animate(_ block: @escaping () -> Void) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7), block)
    }

    private func finishTransition(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.isTransitioning = false
        }
    }
}
