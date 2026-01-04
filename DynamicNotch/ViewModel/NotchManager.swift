import Combine
import SwiftUI

final class NotchManager: ObservableObject {
    @Published var current: NotchContent = .none

    private var isTransitioning = false

    func show(_ content: NotchContent) {
        guard current != content, !isTransitioning else { return }
        isTransitioning = true
        
        if current != .none {
            hide(animated: true) { [weak self] in
                guard let self = self else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.current = content
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isTransitioning = false
                }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.current = content
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isTransitioning = false
            }
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            withAnimation(.spring(response: 0.4)) {
                self.current = .none
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion?()
            }
        } else {
            self.current = .none
            completion?()
        }
    }
}
