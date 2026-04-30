import Foundation

protocol NetworkMonitoring: AnyObject {
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)? { get set }
    var currentWiFiName: String? { get }
    var currentVPNName: String? { get }
    var isInternetAvailable: Bool { get }

    func startMonitoring()
    func stopMonitoring()
}
