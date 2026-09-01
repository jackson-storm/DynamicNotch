import Foundation
import Combine

final class FocusService {
    var onEvent: ((FocusEvent) -> Void)?

    private var cancellables = Set<AnyCancellable>()
    private let manager = DoNotDisturbManager.shared

    private var lastActiveState: Bool?
    private var lastModeType: FocusModeType?

    // Focus activation and the specific mode metadata (identifier/name) can arrive
    // in separate updates. When activation lands first without metadata we hold this
    // fallback briefly so real metadata (e.g. Work) can win the race, instead of
    // flashing the generic Do Not Disturb crescent and then correcting itself.
    private var pendingFallback: DispatchWorkItem?
    private let metadataGracePeriod: TimeInterval = 0.6

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

            let hasMetadata = !identifier.isEmpty || !name.isEmpty
            let modeType = FocusModeType.resolve(
                identifier: identifier,
                name: name
            )

            if isActive {
                if hasMetadata {
                    self.cancelPendingFallback()
                    self.emitFocusOn(modeType)
                } else if self.lastActiveState == true {
                    // Already showing a resolved mode; ignore transient empty updates.
                } else {
                    // Focus is on but the mode is not known yet. Wait a moment for the
                    // metadata; if none arrives, fall back to Do Not Disturb.
                    self.schedulePendingFallback()
                }
            } else {
                self.cancelPendingFallback()
                if self.lastActiveState == true {
                    self.lastActiveState = false
                    self.lastModeType = modeType
                    self.onEvent?(.FocusOff(modeType))
                }
            }
        }
        .store(in: &cancellables)
    }

    private func emitFocusOn(_ modeType: FocusModeType) {
        guard lastActiveState != true || lastModeType != modeType else { return }
        lastActiveState = true
        lastModeType = modeType
        onEvent?(.FocusOn(modeType))
    }

    private func schedulePendingFallback() {
        guard pendingFallback == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingFallback = nil
            guard self.manager.isDoNotDisturbActive else { return }
            self.emitFocusOn(.doNotDisturb)
        }
        pendingFallback = work
        DispatchQueue.main.asyncAfter(deadline: .now() + metadataGracePeriod, execute: work)
    }

    private func cancelPendingFallback() {
        pendingFallback?.cancel()
        pendingFallback = nil
    }
}
