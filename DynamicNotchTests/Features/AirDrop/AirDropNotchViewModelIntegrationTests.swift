import AppKit
import XCTest
@testable import DynamicNotch

@MainActor
final class AirDropNotchViewModelIntegrationTests: XCTestCase {
    func testDraggingFilePublishesStartAndEndEvents() async {
        let viewModel = AirDropNotchViewModel()

        viewModel.isDraggingFile = true
        XCTAssertEqual(viewModel.event, .dragStarted)

        viewModel.event = nil
        viewModel.isDraggingFile = false

        await assertEventually {
            await MainActor.run { viewModel.event == .dragEnded }
        }
    }

    func testHandleDropPublishesDroppedEventWithResolvedURLs() async {
        let viewModel = AirDropNotchViewModel()
        let url = makeTemporaryFileURL()
        let point = NSPoint(x: 42, y: 24)

        viewModel.handleDrop(
            providers: [NSItemProvider(object: url as NSURL)],
            point: point
        )

        await assertEventually {
            await MainActor.run {
                guard case .dropped(let urls, let dropPoint) = viewModel.event else {
                    return false
                }

                return urls == [url] && dropPoint == point
            }
        }
    }
}

private extension AirDropNotchViewModelIntegrationTests {
    func makeTemporaryFileURL() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")

        FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
        return url
    }
}
