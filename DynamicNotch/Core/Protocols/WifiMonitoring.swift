import Foundation

protocol WifiMonitoring: AnyObject {
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)? { get set }
    var onHotspotBatteryChange: ((Int) -> Void)? { get set }
    var currentWiFiName: String? { get }
    var currentVPNName: String? { get }
    var isInternetAvailable: Bool { get }
    var currentWiFiSignalLevel: Double { get }
    var currentHotspotBatteryLevel: Int? { get }

    func startMonitoring()
    func stopMonitoring()
}
