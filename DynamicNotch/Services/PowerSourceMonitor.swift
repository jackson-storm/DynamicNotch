import Foundation
import IOKit.ps
import Combine

class PowerSourceMonitor: ObservableObject {
    @Published private(set) var onACPower: Bool = false
    @Published private(set) var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isLowPowerMode: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    private let startMonitoring: Bool

    init(startMonitoring: Bool = true) {
        self.startMonitoring = startMonitoring
        if startMonitoring {
            setupPowerNotifications()
            updatePowerState()
            updateLowPowerMode()
        }
    }
    
    deinit {
        if let rls = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, .defaultMode)
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
    
    private func updateLowPowerMode() {
        if #available(macOS 12.0, *) {
            self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        } else {
            self.isLowPowerMode = false
        }
    }
    
    private func setupPowerNotifications() {
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let instance = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                instance.updatePowerState()
                instance.updateLowPowerMode()
            }
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let rls = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, .defaultMode)
            self.runLoopSource = rls
        }
    }
}

func mockBattery(level: Int, lowPower: Bool = false) -> PowerSourceMonitor {
    let monitor = PowerSourceMonitor.preview(batteryLevel: level)
    monitor.isLowPowerMode = lowPower
    return monitor
}

#if DEBUG
extension PowerSourceMonitor {
    /// Preview/test helper to create a monitor с фиксированными значениями и без реального мониторинга.
    static func preview(batteryLevel: Int, onACPower: Bool = false, isCharging: Bool = false) -> PowerSourceMonitor {
        let monitor = PowerSourceMonitor(startMonitoring: false)
        // Эти свойства private(set), но доступны здесь, так как это расширение в том же файле.
        monitor.batteryLevel = max(0, min(batteryLevel, 100))
        monitor.onACPower = onACPower
        monitor.isCharging = isCharging
        return monitor
    }
}
#endif
