import Foundation
import Combine


final class PowerViewModel: ObservableObject {
    @Published private(set) var shouldShowCharger: Bool = false
    @Published private(set) var isBatteryLevel20PercentOrLower: Bool = false
    @Published private(set) var isBatteryLevel100Percent: Bool = false
    
    let powerMonitor: PowerSourceMonitor
    var isInitialized = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(powerMonitor: PowerSourceMonitor) {
        self.powerMonitor = powerMonitor
        setupBindings()
    }
    
    private func setupBindings() {
        powerMonitor.$onACPower
            .removeDuplicates()
            .sink { [weak self] onAC in
                guard let self = self else { return }
                if !self.isInitialized { return }
                self.shouldShowCharger = onAC
            }
            .store(in: &cancellables)
        
        powerMonitor.$batteryLevel
            .removeDuplicates()
            .sink { [weak self] level in
                guard let self = self else { return }
                
                if !self.isInitialized {
                    self.isBatteryLevel20PercentOrLower = (level <= 20)
                    self.isBatteryLevel100Percent = (level == 100)
                } else {
                    self.isBatteryLevel20PercentOrLower = (level <= 20)
                    self.isBatteryLevel100Percent = (level == 100)
                }
            }
            .store(in: &cancellables)
        
        DispatchQueue.main.async { [weak self] in
            self?.isInitialized = true
        }
    }
}
