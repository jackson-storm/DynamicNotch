import AppKit
import CoreGraphics
import XCTest
@testable import DynamicNotch

final class SystemMediaKeyTapTests: XCTestCase {
    private var tap: SystemMediaKeyTap!
    private var delegate: MediaKeyTapDelegateSpy!

    override func setUp() {
        super.setUp()
        tap = SystemMediaKeyTap()
        delegate = MediaKeyTapDelegateSpy()
        tap.delegate = delegate
        tap.configuration = SystemMediaKeyTapConfiguration(interceptVolume: true, interceptBrightness: true)
    }

    override func tearDown() {
        tap = nil
        delegate = nil
        super.tearDown()
    }

    func testConsumesBrightnessKeyPressedAlone() {
        let result = handle(keyCode: MediaKeyCode.brightnessUp, isKeyDown: true, modifiers: [])

        XCTAssertNil(result)
        XCTAssertEqual(delegate.brightnessCommands, [.increase])
    }

    func testPassesBrightnessKeyHeldWithCommandThrough() {
        let result = handle(keyCode: MediaKeyCode.brightnessDown, isKeyDown: true, modifiers: [.command])

        XCTAssertNotNil(result)
        XCTAssertTrue(delegate.brightnessCommands.isEmpty)
    }

    func testPassesBrightnessKeyHeldWithOptionThrough() {
        let result = handle(keyCode: MediaKeyCode.brightnessUp, isKeyDown: true, modifiers: [.option])

        XCTAssertNotNil(result)
        XCTAssertTrue(delegate.brightnessCommands.isEmpty)
    }

    func testConsumesBrightnessKeyHeldWithOptionAndShift() {
        let result = handle(keyCode: MediaKeyCode.brightnessUp, isKeyDown: true, modifiers: [.option, .shift])

        XCTAssertNil(result)
        XCTAssertEqual(delegate.brightnessGranularities, [.fine])
    }

    func testConsumesKeyUpOfConsumedKeyDown() {
        _ = handle(keyCode: MediaKeyCode.brightnessUp, isKeyDown: true, modifiers: [])

        XCTAssertNil(handle(keyCode: MediaKeyCode.brightnessUp, isKeyDown: false, modifiers: []))
    }

    func testPassesKeyUpThroughAfterPassedThroughKeyDown() {
        _ = handle(keyCode: MediaKeyCode.brightnessDown, isKeyDown: true, modifiers: [.command])

        XCTAssertNotNil(handle(keyCode: MediaKeyCode.brightnessDown, isKeyDown: false, modifiers: []))
    }

    private func handle(
        keyCode: Int32,
        isKeyDown: Bool,
        modifiers: NSEvent.ModifierFlags
    ) -> Unmanaged<CGEvent>? {
        guard let type = CGEventType(rawValue: MediaKeyCode.systemDefinedEventType),
              let event = mediaKeyEvent(keyCode: keyCode, isKeyDown: isKeyDown, modifiers: modifiers) else {
            XCTFail("Failed to build a system-defined media key event")
            return nil
        }

        return tap.handleEvent(type: type, event: event)
    }

    private func mediaKeyEvent(
        keyCode: Int32,
        isKeyDown: Bool,
        modifiers: NSEvent.ModifierFlags
    ) -> CGEvent? {
        let keyState = isKeyDown ? 0xA : 0xB
        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: (Int(keyCode) << 16) | (keyState << 8),
            data2: -1
        )

        return event?.cgEvent
    }
}

private final class MediaKeyTapDelegateSpy: SystemMediaKeyTapDelegate {
    private(set) var volumeCommands: [MediaKeyDirection] = []
    private(set) var brightnessCommands: [MediaKeyDirection] = []
    private(set) var brightnessGranularities: [MediaKeyGranularity] = []
    private(set) var muteToggleCount = 0

    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveVolumeCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    ) {
        volumeCommands.append(direction)
    }

    func mediaKeyTapDidToggleMute(_ tap: SystemMediaKeyTap) {
        muteToggleCount += 1
    }

    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveBrightnessCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    ) {
        brightnessCommands.append(direction)
        brightnessGranularities.append(granularity)
    }
}
