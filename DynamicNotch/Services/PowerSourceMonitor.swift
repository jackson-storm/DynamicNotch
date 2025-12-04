import Foundation
import IOKit.ps
import Combine

class PowerSourceMonitor: ObservableObject {
    @Published private(set) var onACPower: Bool = false
    @Published private(set) var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    
    init() {
        setupPowerNotifications()
        updatePowerState()
    }
    
    deinit {
        if let rls = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, .defaultMode)
        }
    }
    
    private func setupPowerNotifications() {
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let instance = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                instance.updatePowerState()
            }
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let rls = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, .defaultMode)
            self.runLoopSource = rls
        }
    }
    
    func updatePowerState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        var acPower = false
        var levelPercent: Int = 0
        var charging: Bool = false
        
        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: Any] {
                if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                    acPower = (state == kIOPSACPowerValue)
                }
                if let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                   let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                    levelPercent = Int((Double(cur) / Double(max)) * 100.0)
                }
                if let ch = desc[kIOPSIsChargingKey as String] as? Bool {
                    charging = ch
                }
                if let transport = desc[kIOPSTransportTypeKey as String] as? String, transport == kIOPSInternalType {
                    break
                }
            }
        }
        self.onACPower = acPower
        self.batteryLevel = max(0, min(levelPercent, 100))
        self.isCharging = charging
    }
}
