import XCTest
@testable import DynamicNotch

final class MailNotchContentTests: XCTestCase {

    func testIDUsesRegistryID() {
        let message = MailMessage(
            rowID: 123,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: "Preview",
            receivedDate: Date()
        )

        let content = NotificationsNotchContent(
            items: [.mail(message)],
            onOpenMail: { _ in }
        )

        XCTAssertEqual(content.id, NotchContentRegistry.Notifications.messages.id)
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

        let content = NotificationsNotchContent(
            items: [.mail(message)],
            onOpenMail: { _ in }
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 115)
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

        let content = NotificationsNotchContent(
            items: [.mail(message)],
            onOpenMail: { _ in }
        )

        let size = content.size(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 360)
        XCTAssertEqual(size.height, 100)
    }

    func testDynamicIslandSizeWhenSummaryExists() {
        let message = MailMessage(
            rowID: 3,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: "Preview",
            receivedDate: Date()
        )

        let content = NotificationsNotchContent(
            items: [.mail(message)],
            onOpenMail: { _ in }
        )

        let size = content.dynamicIslandSize(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 410)
        XCTAssertEqual(size.height, 112)
    }

    func testDynamicIslandSizeWhenSummaryIsMissing() {
        let message = MailMessage(
            rowID: 4,
            messageIDHeader: "",
            sender: "sender@example.com",
            subject: "Test",
            summary: nil,
            receivedDate: Date()
        )

        let content = NotificationsNotchContent(
            items: [.mail(message)],
            onOpenMail: { _ in }
        )

        let size = content.dynamicIslandSize(
            baseWidth: 200,
            baseHeight: 40
        )

        XCTAssertEqual(size.width, 380)
        XCTAssertEqual(size.height, 100)
    }
}
