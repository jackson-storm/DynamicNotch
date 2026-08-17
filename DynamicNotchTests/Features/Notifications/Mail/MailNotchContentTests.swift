import XCTest
@testable import DynamicNotch

final class MailNotchContentTests: XCTestCase {

    func testIDUsesMessageRowID() {
        let message = MailMessage(
            rowID: 123,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: "Preview",
            receivedDate: Date()
        )

        let content = MailNotchContent(
            message: message,
            onOpen: {}
        )

        XCTAssertEqual(content.id, "mail.message.123")
    }
    
    func testSizeUsesExpandedHeightWhenSummaryExists() {
        let message = MailMessage(
            rowID: 1,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: "Preview",
            receivedDate: Date()
        )

        let content = MailNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 125)
    }

    func testSizeUsesCompactHeightWhenSummaryIsMissing() {
        let message = MailMessage(
            rowID: 2,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: nil,
            receivedDate: Date()
        )

        let content = MailNotchContent(
            message: message,
            onOpen: {}
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 105)
    }
}
