import Foundation

/// DDC/CI Get/Set VCP packets. Only the speaker-volume register is exposed.
nonisolated enum DisplayDDCProtocol {
    static let volume: UInt8 = 0x62

    static func readRequest() -> [UInt8] {
        packet([0x82, 0x01, volume])
    }

    static func writeRequest(_ value: UInt16) -> [UInt8] {
        packet([0x84, 0x03, volume, UInt8(value >> 8), UInt8(value & 0xff)])
    }

    private static func packet(_ bytes: [UInt8]) -> [UInt8] {
        bytes + [bytes.reduce(0x6e ^ 0x51, ^)]
    }

    static func decode(_ bytes: [UInt8], displayID: UInt32) -> DisplayDDCVolume? {
        guard bytes.count >= 11, bytes[0] == 0x6e, bytes[1] == 0x88,
              bytes[2] == 0x02, bytes[3] == 0, bytes[4] == volume,
              bytes.prefix(11).reduce(UInt8(0x50), ^) == 0 else { return nil }
        let maximum = UInt16(bytes[6]) << 8 | UInt16(bytes[7])
        let current = UInt16(bytes[8]) << 8 | UInt16(bytes[9])
        guard maximum > 0, current <= maximum else { return nil }
        return DisplayDDCVolume(displayID: displayID, current: current, maximum: maximum)
    }
}

nonisolated struct DisplayDDCVolume: Sendable, Equatable {
    let displayID: UInt32
    let current: UInt16
    let maximum: UInt16
    var fraction: Double { Double(current) / Double(maximum) }
}

nonisolated protocol DisplayVolumeControlling: Sendable {
    func readVolume(displayID: UInt32) async -> DisplayDDCVolume?
    func setVolume(_ fraction: Double, displayID: UInt32) async -> DisplayDDCVolume?
}
