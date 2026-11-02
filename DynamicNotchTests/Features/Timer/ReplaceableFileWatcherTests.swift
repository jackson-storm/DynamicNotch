import XCTest
@testable import DynamicNotch

final class ReplaceableFileWatcherTests: XCTestCase {
    private var directoryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReplaceableFileWatcherTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directoryURL)
        try super.tearDownWithError()
    }

    func testCallbackFiresAfterEachAtomicReplacement() throws {
        let watchedURL = directoryURL.appendingPathComponent("watched.plist")
        try Data("initial".utf8).write(to: watchedURL)

        let queue = DispatchQueue(label: "ReplaceableFileWatcherTests")
        let counter = CallbackCounter()
        let watcher = ReplaceableFileWatcher(path: watchedURL.path, queue: queue) {
            counter.increment()
        }

        XCTAssertTrue(queue.sync { watcher.start() })
        defer { queue.sync { watcher.cancel() } }

        for replacement in 1...3 {
            let callbackFired = expectation(description: "callback after replacement \(replacement)")
            queue.sync {
                counter.onIncrement = { count in
                    if count == replacement {
                        callbackFired.fulfill()
                    }
                }
            }

            try replaceAtomically(watchedURL, with: "replacement \(replacement)")
            wait(for: [callbackFired], timeout: 2)
        }

        // Let any trailing events drain before reading the final count.
        queue.sync {}
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertEqual(queue.sync { counter.count }, 3)
    }

    func testCancelStopsCallbacks() throws {
        let watchedURL = directoryURL.appendingPathComponent("cancelled.plist")
        try Data("initial".utf8).write(to: watchedURL)

        let queue = DispatchQueue(label: "ReplaceableFileWatcherTests.cancel")
        let counter = CallbackCounter()
        let watcher = ReplaceableFileWatcher(path: watchedURL.path, queue: queue) {
            counter.increment()
        }

        XCTAssertTrue(queue.sync { watcher.start() })
        queue.sync { watcher.cancel() }

        try replaceAtomically(watchedURL, with: "after cancel")
        Thread.sleep(forTimeInterval: 0.2)

        XCTAssertEqual(queue.sync { counter.count }, 0)
    }

    func testStartFailsWhenFileIsMissing() {
        let queue = DispatchQueue(label: "ReplaceableFileWatcherTests.missing")
        let watcher = ReplaceableFileWatcher(
            path: directoryURL.appendingPathComponent("missing.plist").path,
            queue: queue
        ) {}

        XCTAssertFalse(queue.sync { watcher.start() })
    }

    private func replaceAtomically(_ url: URL, with contents: String) throws {
        let temporaryURL = directoryURL.appendingPathComponent(".\(UUID().uuidString).tmp")
        try Data(contents.utf8).write(to: temporaryURL)
        XCTAssertEqual(rename(temporaryURL.path, url.path), 0, String(cString: strerror(errno)))
    }
}

/// Mutated only on the watcher's queue.
private nonisolated final class CallbackCounter: @unchecked Sendable {
    private(set) var count = 0
    var onIncrement: ((Int) -> Void)?

    func increment() {
        count += 1
        onIncrement?(count)
    }
}
