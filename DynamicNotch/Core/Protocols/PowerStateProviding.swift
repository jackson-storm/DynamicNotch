import Foundation

protocol PowerStateProviding: AnyObject {
    var onACPower: Bool { get }
    var batteryLevel: Int { get }
    var onPowerStateChange: ((_ onACPower: Bool, _ batteryLevel: Int) -> Void)? { get set }
}
