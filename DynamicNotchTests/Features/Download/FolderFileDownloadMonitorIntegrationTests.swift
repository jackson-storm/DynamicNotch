import XCTest
@testable import DynamicNotch

final class FolderFileDownloadMonitorIntegrationTests: XCTestCase {
    func testSafariStyleDownloadPackagePublishesActiveTransfer() {
        let tempDirectory = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let monitor = FolderFileDownloadMonitor(monitoredDirectories: [tempDirectory])
        let expectation = expectation(description: "publishes safari download package")

        monitor.onSnapshotChange = { transfers in
            guard let transfer = transfers.first else { return }
            XCTAssertEqual(transfer.displayName, "archive.zip")
            XCTAssertEqual(transfer.directoryName, tempDirectory.lastPathComponent)
            XCTAssertTrue(transfer.isTemporaryFile)
            XCTAssertGreaterThan(transfer.byteCount, 0)
            expectation.fulfill()
        }

        monitor.startMonitoring()

        let packageURL = tempDirectory.appendingPathComponent("archive.zip.download")
        try? FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        let partialFileURL = packageURL.appendingPathComponent("archive.zip")
        FileManager.default.createFile(
            atPath: partialFileURL.path,
            contents: Data(repeating: 0xA, count: 32_768)
        )

        wait(for: [expectation], timeout: 3.0)
        monitor.stopMonitoring()
    }
}

private extension FolderFileDownloadMonitorIntegrationTests {
    func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
