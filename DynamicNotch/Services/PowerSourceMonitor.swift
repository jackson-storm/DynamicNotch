import Foundation
import IOKit.ps
import Combine

class PowerSourceMonitor: ObservableObject {
    @Published private(set) var onACPower: Bool = false
    @Published private(set) var batteryLevel: Int = 0
    @Published private(set) var isCharging: Bool = false

    #if os(macOS)
    private var runLoopSource: CFRunLoopSource?

    init() {
        #if os(macOS)
        setupPowerNotifications()
        // Initial read so UI reflects current state immediately
        updatePowerState()
        #endif
    }

    deinit {
        #if os(macOS)
        if let rls = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, .defaultMode)
        }
        #endif
    }

    private func setupPowerNotifications() {
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let instance = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            // Ensure UI updates happen on the main queue
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
    #endif

    #if os(macOS)
    func updatePowerState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        var acPower = false
        var levelPercent: Int = 0
        var charging: Bool = false

        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: Any] {
                // Determine whether we're on AC power
                if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                    acPower = (state == kIOPSACPowerValue)
                }
                // Battery percentage
                if let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                   let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                    levelPercent = Int((Double(cur) / Double(max)) * 100.0)
                }
                // Charging flag
                if let ch = desc[kIOPSIsChargingKey as String] as? Bool {
                    charging = ch
                }
                // Prefer internal battery info when present
                if let transport = desc[kIOPSTransportTypeKey as String] as? String, transport == kIOPSInternalType {
                    break
                }
            }
        }

        self.onACPower = acPower
        self.batteryLevel = max(0, min(levelPercent, 100))
        self.isCharging = charging
    }
    #endif
}
