import SwiftUI
import Combine

class ChargerViewModel: ObservableObject {
    @Published private(set) var powerSourceMonitor: PowerSourceMonitor
    private let notchManager: NotchManager
    
    private var hasAppeared = false
    
    init(powerSourceMonitor: PowerSourceMonitor, notchManager: NotchManager) {
        self.powerSourceMonitor = powerSourceMonitor
        self.notchManager = notchManager
    }
    
    func simulateInitialCharging() {
        guard hasAppeared else { return }
        
        if powerSourceMonitor.onACPower {
            showChargingEvent()
        }
    }
    
    func markAsAppeared() {
        hasAppeared = true
    }
    
    func showChargingEvent() {
        let module = ChargerNotch(powerSourceMonitor: powerSourceMonitor)
        notchManager.show(module, autoHideAfter: 4)
    }
    
    func hideChargingEvent() {
        let module = ChargerNotch(powerSourceMonitor: powerSourceMonitor)
        notchManager.hide(module)
    }
    
    func updateChargingState(isOnAC: Bool) {
        if isOnAC {
            showChargingEvent()
        } else {
            hideChargingEvent()
        }
    }
}
