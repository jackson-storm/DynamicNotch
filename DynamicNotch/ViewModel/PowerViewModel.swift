import Foundation
import Combine

final class PowerViewModel: ObservableObject {
    @Published private(set) var shouldShowCharger: Bool = false
    @Published private(set) var isBatteryLevel20PercentOrLower: Bool = false
    
    let powerMonitor: PowerSourceMonitor
    
    private var cancellables = Set<AnyCancellable>()
    private var isFirstCheck = true
    
    init(powerMonitor: PowerSourceMonitor) {
        self.powerMonitor = powerMonitor
        bindPower()
    }
    
    private func bindPower() {
        powerMonitor.$onACPower
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] onAC in
                guard let self = self else { return }

                if self.isFirstCheck {
                    self.isFirstCheck = false
                    return
                }
                self.shouldShowCharger = onAC
            }
            .store(in: &cancellables)

        powerMonitor.$batteryLevel
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.isBatteryLevel20PercentOrLower = (level <= 20)
            }
            .store(in: &cancellables)
    }
}
