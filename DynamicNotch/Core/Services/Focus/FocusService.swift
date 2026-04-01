import Foundation
import Combine

final class FocusService {
    var onEvent: ((FocusEvent) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private let manager = DoNotDisturbManager.shared

    func start() {
        manager.startMonitoring()

        manager.$isDoNotDisturbActive
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                guard let self else { return }

                if isActive {
                    self.onEvent?(.FocusOn)
                } else {
                    self.onEvent?(.FocusOff)
                }
            }
            .store(in: &cancellables)
    }
}
