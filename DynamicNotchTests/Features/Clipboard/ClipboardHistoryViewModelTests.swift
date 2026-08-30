import AppKit
import XCTest
@testable import DynamicNotch

@MainActor
final class ClipboardHistoryViewModelTests: XCTestCase {
    func testDuplicatePayloadMovesToFrontWithoutGrowingHistory() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(monitor: monitor)

        monitor.publish(.init(payload: .text("first"), sourceApplicationName: "Notes", capturedAt: date(1)))
        monitor.publish(.init(payload: .text("second"), sourceApplicationName: "Safari", capturedAt: date(2)))
        monitor.publish(.init(payload: .text("first"), sourceApplicationName: "Mail", capturedAt: date(3)))

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.items.map(\.payload), [.text("first"), .text("second")])
        XCTAssertEqual(viewModel.items.first?.sourceApplicationName, "Mail")
        XCTAssertEqual(viewModel.items.first?.capturedAt, date(3))
    }

    func testHistoryUsesConfiguredBound() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(monitor: monitor, historyLimit: 5)

        for index in 0..<7 {
            monitor.publish(
                .init(
                    payload: .text("item-\(index)"),
                    sourceApplicationName: nil,
                    capturedAt: date(index)
                )
            )
        }

        XCTAssertEqual(viewModel.items.count, 5)
        XCTAssertEqual(viewModel.items.first?.payload, .text("item-6"))
        XCTAssertEqual(viewModel.items.last?.payload, .text("item-2"))
    }

    func testRestoreWritesSelectedOlderPayloadWithoutCreatingAnotherItem() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(monitor: monitor)
        var didPrepareForRestore = false
        viewModel.onWillRestore = { didPrepareForRestore = true }

        monitor.publish(.init(payload: .text("older"), sourceApplicationName: nil, capturedAt: date(1)))
        monitor.publish(.init(payload: .text("newer"), sourceApplicationName: nil, capturedAt: date(2)))
        let olderItem = viewModel.items[1]

        XCTAssertTrue(viewModel.restore(olderItem))
        XCTAssertTrue(didPrepareForRestore)
        XCTAssertEqual(monitor.writtenPayloads, [.text("older")])
        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.currentItemID, olderItem.id)
    }

    func testRestoreFailureIsExposedWithoutChangingCurrentItem() {
        let monitor = TestClipboardMonitor()
        monitor.writeResult = false
        let viewModel = ClipboardHistoryViewModel(monitor: monitor)

        monitor.publish(.init(payload: .text("first"), sourceApplicationName: nil, capturedAt: date(1)))
        let item = viewModel.items[0]

        XCTAssertFalse(viewModel.restore(item))
        XCTAssertEqual(viewModel.currentItemID, item.id)
        XCTAssertEqual(viewModel.restoreFailure?.itemID, item.id)
        XCTAssertEqual(viewModel.restoreFailure?.message, "Couldn’t copy this item again.")
    }

    func testMissingFilesAreNotWrittenBackToClipboard() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(
            monitor: monitor,
            fileExists: { _ in false }
        )
        let missingFile = URL(fileURLWithPath: "/tmp/dynamic-notch-missing-file")

        monitor.publish(.init(payload: .files([missingFile]), sourceApplicationName: "Finder", capturedAt: date(1)))
        let item = viewModel.items[0]

        XCTAssertFalse(viewModel.restore(item))
        XCTAssertTrue(monitor.writtenPayloads.isEmpty)
        XCTAssertEqual(viewModel.restoreFailure?.message, "The original file is no longer available.")
    }

    func testCurrentStateClearsWhenCurrentItemIsTrimmed() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(monitor: monitor, historyLimit: 6)

        for index in 0..<6 {
            monitor.publish(.init(payload: .text("item-\(index)"), sourceApplicationName: nil, capturedAt: date(index)))
        }
        let oldest = viewModel.items.last!
        XCTAssertTrue(viewModel.restore(oldest))
        XCTAssertEqual(viewModel.currentItemID, oldest.id)

        viewModel.updateHistoryLimit(5)

        XCTAssertNil(viewModel.currentItemID)
    }

    func testCaptureCallbackReceivesTheStoredItem() {
        let monitor = TestClipboardMonitor()
        let viewModel = ClipboardHistoryViewModel(monitor: monitor)
        var capturedItem: ClipboardHistoryItem?
        viewModel.onDidCapture = { capturedItem = $0 }

        monitor.publish(.init(payload: .image(Data([0x01])), sourceApplicationName: nil, capturedAt: date(1)))

        XCTAssertEqual(capturedItem, viewModel.items.first)
    }

    func testSensitiveAndTransientPasteboardTypesAreIgnored() {
        XCTAssertTrue(
            SystemClipboardMonitor.shouldIgnore(
                types: [.init("org.nspasteboard.ConcealedType")]
            )
        )
        XCTAssertTrue(
            SystemClipboardMonitor.shouldIgnore(
                types: [.init("com.example.password-token")]
            )
        )
        XCTAssertFalse(SystemClipboardMonitor.shouldIgnore(types: [.string]))
    }

    func testTextPreviewIsNormalizedAndBounded() {
        let payload = ClipboardPayload.text(String(repeating: "word\n", count: 100))

        XCTAssertFalse(payload.preview.contains("\n"))
        XCTAssertLessThanOrEqual(payload.preview.count, 161)
        XCTAssertTrue(payload.preview.hasSuffix("…"))
    }

    func testFilePayloadRejectsOversizedSelectionsWithoutTruncatingThem() {
        let urls = (0...SystemClipboardMonitor.maximumFileCount).map {
            URL(fileURLWithPath: "/tmp/file-\($0)")
        }

        XCTAssertNil(SystemClipboardMonitor.filePayload(from: urls))
        XCTAssertEqual(
            SystemClipboardMonitor.filePayload(from: Array(urls.prefix(SystemClipboardMonitor.maximumFileCount))),
            .files(Array(urls.prefix(SystemClipboardMonitor.maximumFileCount)))
        )
    }

    private func date(_ value: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(value))
    }
}

@MainActor
private final class TestClipboardMonitor: ClipboardMonitoring {
    var onClipboardChange: ((ClipboardSnapshot) -> Void)?
    var writeResult = true
    private(set) var writtenPayloads: [ClipboardPayload] = []

    func startMonitoring() {}
    func stopMonitoring() {}

    func write(_ payload: ClipboardPayload) -> Bool {
        writtenPayloads.append(payload)
        return writeResult
    }

    func publish(_ snapshot: ClipboardSnapshot) {
        onClipboardChange?(snapshot)
    }
}
