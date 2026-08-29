import XCTest
@testable import DynamicNotch

final class MessagesNotchContentTests: XCTestCase {

    func testIDUsesRegistryID() {
        let message = MessagesMessage(
            rowID: 123,
            guid: "test-guid-1",
            sender: "Jane Doe",
            senderHandle: "+15551234567",
            text: "Hello!",
            receivedDate: Date(),
            isFromMe: false
        )

        let content = MessagesNotchContent(
            message: message,
            onOpen: {}
        )

        XCTAssertEqual(content.id, NotchContentRegistry.Notifications.messages.id)
    }

    func testSizeUsesExpandedHeightWhenTextExists() {
        let message = MessagesMessage(
            rowID: 1,
            guid: "test-guid-2",
            sender: "Jane Doe",
            senderHandle: "+15551234567",
            text: "How are you doing?",
            receivedDate: Date(),
            isFromMe: false
        )

        let content = MessagesNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 120)
    }

    func testSizeUsesCompactHeightWhenTextIsEmpty() {
        let message = MessagesMessage(
            rowID: 2,
            guid: "test-guid-3",
            sender: "Jane Doe",
            senderHandle: "+15551234567",
            text: "   ",
            receivedDate: Date(),
            isFromMe: false
        )

        let content = MessagesNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 100)
    }

    func testDynamicIslandSizeWhenTextExists() {
        let message = MessagesMessage(
            rowID: 3,
            guid: "test-guid-4",
            sender: "Jane Doe",
            senderHandle: "+15551234567",
            text: "Let's grab lunch!",
            receivedDate: Date(),
            isFromMe: false
        )

        let content = MessagesNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.dynamicIslandSize(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 410)
        XCTAssertEqual(size.height, 120)
    }

    func testDynamicIslandSizeWhenTextIsEmpty() {
        let message = MessagesMessage(
            rowID: 4,
            guid: "test-guid-5",
            sender: "Jane Doe",
            senderHandle: "+15551234567",
            text: "",
            receivedDate: Date(),
            isFromMe: false
        )

        let content = MessagesNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.dynamicIslandSize(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 380)
        XCTAssertEqual(size.height, 100)
    }
}
