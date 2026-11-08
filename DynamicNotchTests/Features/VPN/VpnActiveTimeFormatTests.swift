import XCTest
@testable import DynamicNotch

final class VpnActiveTimeFormatTests: XCTestCase {
    func testTenMinutesOrLessFormatsMinutesAndSecondsWithoutLeadingZeroOnMinutes() {
        XCTAssertEqual(VpnActiveNotchView.formattedTime(0), "0:00")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(5), "0:05")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(59), "0:59")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(60), "1:00")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(599), "9:59")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(600), "10:00")
    }

    func testAboveTenMinutesShowsWholeMinutes() {
        XCTAssertEqual(VpnActiveNotchView.formattedTime(601), "10m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(659), "10m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(660), "11m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(900), "15m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(3599), "59m")
    }

    func testAnHourOrMoreShowsHoursAndMinutes() {
        XCTAssertEqual(VpnActiveNotchView.formattedTime(3600), "1h 0m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(3660), "1h 1m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(5 * 3600 + 30 * 60 + 59), "5h 30m")
        XCTAssertEqual(VpnActiveNotchView.formattedTime(23 * 3600 + 59 * 60 + 59), "23h 59m")
    }
}
