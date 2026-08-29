import AppKit
import XCTest
@testable import DynamicNotch

final class SystemMediaKeyTapConfigurationTests: XCTestCase {
    private let configuration = SystemMediaKeyTapConfiguration(
        interceptVolume: true,
        interceptBrightness: true
    )

    func testInterceptsBrightnessKeyWithoutModifiers() {
        XCTAssertTrue(configuration.intercepts(keyCode: MediaKeyCode.brightnessDown, modifiers: []))
        XCTAssertTrue(configuration.intercepts(keyCode: MediaKeyCode.brightnessUp, modifiers: []))
    }

    func testInterceptsBrightnessKeyWithFineAdjustmentModifiers() {
        XCTAssertTrue(
            configuration.intercepts(keyCode: MediaKeyCode.brightnessUp, modifiers: [.option, .shift])
        )
    }

    func testInterceptsVolumeKeyWithShift() {
        XCTAssertTrue(configuration.intercepts(keyCode: MediaKeyCode.volumeUp, modifiers: [.shift]))
    }

    func testIgnoresKeyboardStateModifiers() {
        XCTAssertTrue(
            configuration.intercepts(keyCode: MediaKeyCode.brightnessUp, modifiers: [.function, .capsLock, .numericPad])
        )
    }

    func testSkipsBrightnessKeyHeldWithCommand() {
        XCTAssertFalse(configuration.intercepts(keyCode: MediaKeyCode.brightnessDown, modifiers: [.command]))
        XCTAssertFalse(
            configuration.intercepts(keyCode: MediaKeyCode.brightnessDown, modifiers: [.command, .shift])
        )
    }

    func testSkipsBrightnessKeyHeldWithControl() {
        XCTAssertFalse(configuration.intercepts(keyCode: MediaKeyCode.brightnessUp, modifiers: [.control]))
    }

    func testSkipsMediaKeyHeldWithOptionAlone() {
        XCTAssertFalse(configuration.intercepts(keyCode: MediaKeyCode.brightnessUp, modifiers: [.option]))
        XCTAssertFalse(configuration.intercepts(keyCode: MediaKeyCode.volumeUp, modifiers: [.option]))
    }

    func testSkipsDisabledMediaKeys() {
        let brightnessOnly = SystemMediaKeyTapConfiguration(interceptVolume: false, interceptBrightness: true)

        XCTAssertFalse(brightnessOnly.intercepts(keyCode: MediaKeyCode.volumeDown, modifiers: []))
        XCTAssertFalse(brightnessOnly.intercepts(keyCode: MediaKeyCode.mute, modifiers: []))
        XCTAssertTrue(brightnessOnly.intercepts(keyCode: MediaKeyCode.brightnessDown, modifiers: []))
    }

    func testSkipsUnknownKeyCode() {
        XCTAssertFalse(configuration.intercepts(keyCode: 16, modifiers: []))
    }
}
