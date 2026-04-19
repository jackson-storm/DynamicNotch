import XCTest
@testable import DynamicNotch

@MainActor
final class DownloadViewModelIntegrationTests: XCTestCase {
    func testStartMonitoringStartsUnderlyingMonitorOnlyOnce() {
        let monitor = FakeFileDownloadMonitor()
        let viewModel = DownloadViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        viewModel.startMonitoring()

        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testPublishingDownloadsEmitsStartedAndStoppedEvents() {
        let monitor = FakeFileDownloadMonitor()
        let viewModel = DownloadViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        viewModel.startMonitoring()
        monitor.publish([makeDownloadSnapshot()])

        XCTAssertEqual(viewModel.event, .started)
        XCTAssertEqual(viewModel.activeDownloads.count, 1)

        monitor.publish([])

        XCTAssertEqual(viewModel.event, .stopped)
        XCTAssertTrue(viewModel.activeDownloads.isEmpty)
    }

    func testPrimaryDownloadUsesMostRecentlyUpdatedDownload() {
        let monitor = FakeFileDownloadMonitor()
        let viewModel = DownloadViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        let olderDownload = makeDownloadSnapshot(
            path: "/tmp/older.zip",
            displayName: "older.zip",
            lastUpdatedAt: .now.addingTimeInterval(-4)
        )
        let newerDownload = makeDownloadSnapshot(
            path: "/tmp/newer.zip",
            displayName: "newer.zip",
            directoryName: "Desktop",
            lastUpdatedAt: .now
        )

        monitor.publish([olderDownload, newerDownload])

        XCTAssertEqual(viewModel.primaryDownload?.displayName, "newer.zip")
        XCTAssertEqual(viewModel.additionalDownloadCount, 1)
    }

    #if DEBUG
    func testDebugPreviewOverridesLiveDownloadsAndRestoresMonitorStateWhenHidden() {
        let monitor = FakeFileDownloadMonitor()
        let viewModel = DownloadViewModel(monitor: monitor)
        TestLifetime.retain(viewModel)

        let liveDownload = makeDownloadSnapshot(
            path: "/tmp/live.zip",
            displayName: "live.zip",
            directoryName: "Downloads",
            lastUpdatedAt: .now.addingTimeInterval(-6)
        )

        monitor.publish([liveDownload])
        XCTAssertEqual(viewModel.primaryDownload?.displayName, "live.zip")

        viewModel.showDebugPreviewDownloadsIfNeeded()

        XCTAssertEqual(viewModel.primaryDownload?.displayName, "DebugExportBigNameForFile.mov")
        XCTAssertEqual(viewModel.additionalDownloadCount, 1)

        let updatedLiveDownload = makeDownloadSnapshot(
            path: "/tmp/live-new.zip",
            displayName: "live-new.zip",
            directoryName: "Desktop",
            lastUpdatedAt: .now
        )

        monitor.publish([updatedLiveDownload])
        XCTAssertEqual(viewModel.primaryDownload?.displayName, "DebugExportBigNameForFile.mov")

        viewModel.hideDebugPreviewDownloadsIfNeeded()
        XCTAssertEqual(viewModel.primaryDownload?.displayName, "live-new.zip")
        XCTAssertEqual(viewModel.additionalDownloadCount, 0)
    }
    #endif
}

private func makeDownloadSnapshot(
    path: String = "/tmp/archive.zip",
    displayName: String = "archive.zip",
    directoryName: String = "Downloads",
    byteCount: Int64 = 2_048_000,
    estimatedTotalByteCount: Int64 = 4_096_000,
    progress: Double = 0.5,
    startedAt: Date = .now.addingTimeInterval(-5),
    lastUpdatedAt: Date = .now,
    isTemporaryFile: Bool = false,
    bytesPerSecond: Int64 = 0
) -> DownloadModel {
    DownloadModel(
        url: URL(fileURLWithPath: path),
        displayName: displayName,
        directoryName: directoryName,
        byteCount: byteCount,
        estimatedTotalByteCount: estimatedTotalByteCount,
        progress: progress,
        startedAt: startedAt,
        lastUpdatedAt: lastUpdatedAt,
        isTemporaryFile: isTemporaryFile,
        bytesPerSecond: bytesPerSecond
    )
}
