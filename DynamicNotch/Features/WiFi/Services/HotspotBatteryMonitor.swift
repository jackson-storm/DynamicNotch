//
//  HotspotBatteryMonitor.swift
//  DynamicNotch
//

import Foundation
import Combine

final class HotspotBatteryMonitor: NSObject, ObservableObject {
    static let shared = HotspotBatteryMonitor()
    
    private var session: NSObject?
    private var isBrowsing = false
    @Published private(set) var currentBatteryLevel: Int?
    var onBatteryLevelChange: ((Int) -> Void)?

    override init() {
        super.init()
        print("[HotspotBatteryMonitor] Initializing HotspotBatteryMonitor...")
        setupSession()
    }

    deinit {
        stopBrowsing()
    }

    private func setupSession() {
        guard let bundle = Bundle(path: "/System/Library/PrivateFrameworks/Sharing.framework") else {
            print("[HotspotBatteryMonitor] ERROR: Could not locate Sharing.framework")
            return
        }
        bundle.load()
        guard let sessionClass = NSClassFromString("SFRemoteHotspotSession") as? NSObject.Type else {
            print("[HotspotBatteryMonitor] ERROR: Could not load SFRemoteHotspotSession class")
            return
        }
        let sess = sessionClass.init()
        sess.setValue(self, forKey: "delegate")
        self.session = sess
        print("[HotspotBatteryMonitor] SFRemoteHotspotSession created successfully.")
    }

    func startBrowsing() {
        guard let session = session else {
            print("[HotspotBatteryMonitor] Cannot startBrowsing: session is nil")
            return
        }
        guard !isBrowsing else { return }
        isBrowsing = true
        print("[HotspotBatteryMonitor] Calling startBrowsing on SFRemoteHotspotSession")
        session.perform(Selector(("startBrowsing")))
    }

    func stopBrowsing() {
        guard let session = session else { return }
        guard isBrowsing else { return }
        isBrowsing = false
        print("[HotspotBatteryMonitor] Calling stopBrowsing on SFRemoteHotspotSession")
        session.perform(Selector(("stopBrowsing")))
    }

    func resetBatteryLevel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentBatteryLevel = nil
        }
    }

    @objc func session(_ session: AnyObject, updatedFoundDevices devices: [NSObject]) {
        guard isBrowsing else { return }
        print("[HotspotBatteryMonitor] updatedFoundDevices received with \(devices.count) device(s)")
        for device in devices {
            let name = device.value(forKey: "deviceName") as? String ?? "Unknown"
            let battery = (device.value(forKey: "batteryLife") as? NSNumber)?.intValue
            let signal = device.value(forKey: "signalStrength") as? NSNumber
            print("[HotspotBatteryMonitor] -> Device: '\(name)', batteryLife: \(String(describing: battery)), signal: \(String(describing: signal))")
            if let battery = battery, battery > 0 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isBrowsing else { return }
                    print("[HotspotBatteryMonitor] Updated currentBatteryLevel = \(battery)%")
                    self.currentBatteryLevel = battery
                    self.onBatteryLevelChange?(battery)
                }
                break
            }
        }
    }
}
