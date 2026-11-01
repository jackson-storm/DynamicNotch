import Foundation
import CoreGraphics

@main
struct IslandToolsTests {
    @MainActor
    static func main() async {
        do { try await run() }
        catch { print("FAIL: \(error)"); exit(1) }
    }

    @MainActor
    static func run() async throws {
        var passed = 0
        func expect(_ condition: @autoclosure () -> Bool, _ label: String) throws {
            guard condition() else { throw TestFailure(message: label) }
            passed += 1
        }
        func calculate(_ input: [MiniCalculatorEngine.Key]) -> MiniCalculatorEngine {
            var engine = MiniCalculatorEngine()
            input.forEach { engine.press($0) }
            return engine
        }
        var session = HomePageSessionMemory()
        try expect(session.pageForExpansion(current: "sound", first: "screenshots", at: 90) == "sound", "open page never expires while in use")
        session.didClose(at: 100)
        try expect(session.pageForExpansion(current: "sound", first: "screenshots", at: 104.99) == "sound", "reopening before five seconds retains page")
        try expect(session.pageForExpansion(current: "sound", first: "screenshots", at: 150) == "sound", "opening consumes the close deadline")
        session.didClose(at: 200)
        try expect(session.pageForExpansion(current: "calculator", first: "screenshots", at: 205) == "screenshots", "five seconds resets to the first configured page")
        session.didClose(at: 300)
        try expect(session.pageForExpansion(current: "sound", first: "timer", at: 400) == "timer", "expiry respects a reordered first page")
        session.didClose(at: 500)
        _ = session.pageForExpansion(current: "sound", first: "timer", at: 501)
        session.didClose(at: 502)
        try expect(session.pageForExpansion(current: "sound", first: "timer", at: 506) == "sound", "a fresh close starts a fresh five seconds")
        let ru = Locale(identifier: "ru_RU")
        var c = calculate([.digit(2), .operation(.add), .digit(3), .operation(.multiply), .digit(4), .equals])
        try expect(c.value == Decimal(14), "multiplication has precedence")
        c = calculate([.digit(0), .decimal, .digit(1), .operation(.add), .digit(0), .decimal, .digit(2), .equals])
        try expect(c.value == Decimal(string: "0.3"), "decimal arithmetic is exact")
        try expect(c.display(locale: ru) == "0,3", "Russian decimal separator")
        c = calculate([.digit(2), .digit(0), .digit(0), .operation(.add), .digit(1), .digit(0), .percent, .equals])
        try expect(c.value == Decimal(220), "addition percentages are relative")
        c = calculate([.digit(2), .digit(0), .digit(0), .operation(.multiply), .digit(1), .digit(0), .percent, .equals])
        try expect(c.value == Decimal(20), "multiplication percentages are fractions")
        c = calculate([.digit(2), .operation(.add), .digit(3), .equals, .equals])
        try expect(c.value == Decimal(8), "equals repeats the operation")
        c = calculate([.digit(2), .operation(.add), .operation(.multiply), .digit(3), .equals])
        try expect(c.value == Decimal(6), "operator replacement")
        c = calculate([.digit(8), .operation(.divide), .digit(0), .equals])
        try expect(c.hasError, "division by zero reports an error")
        c.press(.digit(7))
        try expect(!c.hasError && c.value == Decimal(7), "digit recovers from error")
        c = calculate([.digit(1), .digit(2), .digit(3), .backspace])
        try expect(c.value == Decimal(12), "backspace removes the last digit")
        c = calculate([.digit(2), .operation(.add), .digit(3), .clear, .digit(4), .equals])
        try expect(c.value == Decimal(6), "clear preserves the pending operation")
        c = calculate([.digit(5), .changeSign, .operation(.add), .digit(2), .equals])
        try expect(c.value == Decimal(-3), "negative operands")
        c = calculate([.digit(1), .decimal, .digit(2), .decimal, .digit(3)])
        try expect(c.display(locale: ru) == "1,23", "duplicate decimal separators are ignored")
        c = calculate([.digit(1)] + Array(repeating: .digit(0), count: 15) + [.operation(.multiply), .digit(1)] + Array(repeating: .digit(0), count: 15) + [.equals])
        try expect(c.value == Decimal(string: "1e30"), "large multiplication retains its value")
        try expect(c.display(locale: ru).lowercased().contains("e"), "large answers use readable exponent notation")

        var strayGesture = HomePageScrollGesture()
        try expect(strayGesture.process(deltaX: 0, deltaY: -60, phase: .changed) == .passThrough, "entering during an existing trackpad gesture must not select a page")

        var pageGesture = HomePageScrollGesture()
        try expect(pageGesture.process(deltaX: 40, deltaY: 1, phase: .began) == .passThrough, "horizontal timer gesture does not turn pages")
        try expect(pageGesture.process(deltaX: 0, deltaY: -40, phase: .began) == .step(1), "vertical swipe selects the next page")
        try expect(pageGesture.process(deltaX: 0, deltaY: -80, phase: .changed) == .consume, "one swipe changes only one page")
        try expect(pageGesture.process(deltaX: 0, deltaY: -80, phase: .none, momentum: true) == .consume, "momentum cannot turn another page")
        try expect(pageGesture.process(deltaX: 0, deltaY: 40, phase: .began) == .step(-1), "reverse swipe selects the previous page")

        var terminalGesture = HomePageScrollGesture()
        try expect(terminalGesture.process(deltaX: 0, deltaY: -10, phase: .began) == .consume, "small movement starts a vertical gesture")
        try expect(terminalGesture.process(deltaX: 0, deltaY: -80, phase: .ended) == .consume, "terminal delta cannot select a page")
        try expect(terminalGesture.process(deltaX: 0, deltaY: -80, phase: .changed) == .passThrough, "ended gesture cannot restart from a changed event")
        try expect(terminalGesture.process(deltaX: 0, deltaY: -80, phase: .none) == .consume, "phase-less precise tail cannot become a mouse wheel step")
        var unstartedGesture = HomePageScrollGesture()
        try expect(unstartedGesture.process(deltaX: 0, deltaY: -80, phase: .none) == .passThrough, "phase-less precise input cannot start navigation")
        try expect(unstartedGesture.process(deltaX: 0, deltaY: -80, phase: .mayBegin) == .passThrough, "may-begin does not turn a page")
        try expect(unstartedGesture.process(deltaX: 0, deltaY: -40, phase: .began) == .step(1), "actual begin follows may-begin")
        var wheelGesture = HomePageScrollGesture()
        try expect(wheelGesture.process(deltaX: 0, deltaY: -1, phase: .none, precise: false, timestamp: 1) == .step(1), "ordinary mouse wheel still turns pages")
        try expect(wheelGesture.process(deltaX: 0, deltaY: -1, phase: .none, precise: false, timestamp: 1.1) == .consume, "mouse wheel burst cannot skip pages")
        try expect(wheelGesture.process(deltaX: 0, deltaY: 1, phase: .none, precise: false, timestamp: 2) == .step(-1), "later mouse wheel step can reverse direction")
        var cancelledGesture = HomePageScrollGesture()
        _ = cancelledGesture.process(deltaX: 0, deltaY: -5, phase: .began)
        try expect(cancelledGesture.process(deltaX: 0, deltaY: -60, phase: .cancelled) == .consume, "cancelled gesture never selects a page")
        try expect(cancelledGesture.process(deltaX: 0, deltaY: -60, phase: .changed) == .passThrough, "cancelled stream cannot resume without a new begin")

        let minimum = HomePageNavigationLayout.minimumSize(size: CGSize(width: 380, height: 327), pointer: CGPoint(x: 190, y: 280))
        let smallerPage = HomePageNavigationLayout.expandedSize(preferred: CGSize(width: 340, height: 157), minimum: minimum)
        try expect(smallerPage == CGSize(width: 340, height: 304), "shorter page retains pointer with a hover margin")
        let edgeMinimum = HomePageNavigationLayout.minimumSize(size: CGSize(width: 380, height: 327), pointer: CGPoint(x: 370, y: 100))
        try expect(HomePageNavigationLayout.expandedSize(preferred: CGSize(width: 240, height: 157), minimum: edgeMinimum).width == 408, "narrower page retains pointer near the side")
        try expect(HomePageNavigationLayout.minimumSize(size: CGSize(width: 380, height: 327), pointer: CGPoint(x: 500, y: 100)) == .zero, "pointer outside the island cannot enlarge a page")

        var reply: [UInt8] = [0x6e, 0x88, 0x02, 0, 0x62, 0, 0, 100, 0, 48]
        reply.append(reply.reduce(UInt8(0x50), ^))
        try expect(DisplayDDCProtocol.decode(reply, displayID: 3)?.fraction == 0.48, "validated DDC volume reply")
        var corrupt = reply; corrupt[10] ^= 1
        try expect(DisplayDDCProtocol.decode(corrupt, displayID: 3) == nil, "DDC rejects invalid checksums")
        var unsupported = reply; unsupported[3] = 1; unsupported[10] ^= 1
        try expect(DisplayDDCProtocol.decode(unsupported, displayID: 3) == nil, "DDC rejects unsupported VCP replies")
        var wrongRegister = reply; wrongRegister[4] = 0x10; wrongRegister[10] ^= 0x62 ^ 0x10
        try expect(DisplayDDCProtocol.decode(wrongRegister, displayID: 3) == nil, "DDC rejects replies for a different control")
        try expect(DisplayDDCProtocol.writeRequest(0) == [0x84, 0x03, 0x62, 0, 0, 0xda], "DDC mute packet retains zero-valued fields")

        var events: [String] = []
        let copied = try await ScreenshotCaptureFlow.run(
            hide: { events.append("hide") }, restore: { events.append("restore") },
            select: { events.append("select"); return 42 },
            capture: { value in events.append("capture"); return value + 1 },
            copy: { value in events.append("copy:\(value)") }
        )
        try expect(copied && events == ["hide", "select", "capture", "copy:43", "restore"], "hide and copy ordering")
        events = []
        let cancelled = try await ScreenshotCaptureFlow.run(
            hide: { events.append("hide") }, restore: { events.append("restore") },
            select: { () async throws -> Int? in nil },
            capture: { value in events.append("capture"); return value },
            copy: { _ in events.append("copy") }
        )
        try expect(!cancelled && events == ["hide", "restore"], "cancellation leaves the clipboard untouched")
        events = []
        do {
            _ = try await ScreenshotCaptureFlow.run(
                hide: { events.append("hide") }, restore: { events.append("restore") },
                select: { 1 },
                capture: { _ -> Int in throw TestFailure(message: "capture failed") },
                copy: { _ in events.append("copy") }
            )
            throw TestFailure(message: "capture error was swallowed")
        } catch {
            try expect(events == ["hide", "restore"], "capture error always restores the island")
        }
        let capture = ScreenshotCaptureGeometry(
            screenFrame: CGRect(x: -1440, y: -200, width: 1440, height: 900), scale: 2,
            selection: CGRect(x: -1340, y: 400, width: 300, height: 200)
        )
        try expect(capture.sourceRect == CGRect(x: 100, y: 100, width: 300, height: 200), "Cocoa-to-display coordinates on secondary display")
        try expect(capture.pixelWidth == 600 && capture.pixelHeight == 400, "Retina output resolution")
        let outside = ScreenshotCaptureGeometry(screenFrame: CGRect(x: 0, y: 0, width: 100, height: 100), scale: 2, selection: CGRect(x: 200, y: 200, width: 10, height: 10))
        try expect(outside.sourceRect.isEmpty && outside.pixelWidth == 0, "off-screen selections are rejected")
        print("PASS: \(passed) island tool checks")
    }
}

struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
