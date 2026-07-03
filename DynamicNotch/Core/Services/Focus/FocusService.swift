import Foundation
import Combine

final class FocusService {
    var onEvent: ((FocusEvent) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private let manager = DoNotDisturbManager.shared
    
    private var lastActiveState: Bool?
    private var lastModeType: FocusModeType?

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
                if self.lastActiveState != true || self.lastModeType != modeType {
                    self.lastActiveState = true
                    self.lastModeType = modeType
                    self.onEvent?(.FocusOn(modeType))
                }
            } else {
                if self.lastActiveState == true {
                    self.lastActiveState = false
                    self.lastModeType = modeType
                    self.onEvent?(.FocusOff(modeType))
                }
            }
        }
        .store(in: &cancellables)
    }
}
