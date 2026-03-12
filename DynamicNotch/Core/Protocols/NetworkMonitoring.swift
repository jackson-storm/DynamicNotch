import Foundation

protocol NetworkMonitoring: AnyObject {
    var onStatusChange: ((_ wifi: Bool, _ hotspot: Bool, _ vpn: Bool) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
