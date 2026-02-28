import Foundation
import Combine

final class PowerViewModel: ObservableObject {
    @Published var event: PowerEvent?

    let powerService: PowerService
    
    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false

    init(powerService: PowerService) {
        self.powerService = powerService
        setupBindings()
    }

    private func setupBindings() {
        powerService.$onACPower
            .removeDuplicates()
            .sink { [weak self] onAC in
                guard let self else { return }
                guard self.isInitialized else { return }

                if onAC {
                    self.event = .charger
                }
            }
            .store(in: &cancellables)

        powerService.$batteryLevel
            .removeDuplicates()
            .sink { [weak self] level in
                guard let self else { return }
                guard self.isInitialized else { return }

                if level <= 20 {
                    self.event = .lowPower
                }

                if level == 100 {
                    self.event = .fullPower
                }
            }
            .store(in: &cancellables)

        DispatchQueue.main.async {
            self.isInitialized = true
        }
    }
}
