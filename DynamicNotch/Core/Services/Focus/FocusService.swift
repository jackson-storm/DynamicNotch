import Foundation
import Combine

final class FocusService {
    var onEvent: ((FocusEvent) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private let manager = DoNotDisturbManager.shared

    func start() {
        manager.startMonitoring()

        Publishers.CombineLatest3(
            manager.$isDoNotDisturbActive,
            manager.$currentFocusModeIdentifier,
            manager.$currentFocusModeName
        )
        .dropFirst()
        .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .receive(on: RunLoop.main)
        .sink { [weak self] isActive, identifier, name in
            guard let self else { return }

            let modeType = FocusModeType.resolve(
                identifier: identifier,
                name: name
            )

            if isActive {
                self.onEvent?(.FocusOn(modeType))
            } else {
                self.onEvent?(.FocusOff(modeType))
            }
        }
        .store(in: &cancellables)
    }
}
