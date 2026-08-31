import Contacts
import XCTest
@testable import DynamicNotch

@MainActor
final class MessagesContactResolverTests: XCTestCase {

    func testSenderReturnsEmptyFallbackWithoutReadingContactStore() {
        let store = FakeMessagesContactStore(contact: makeContact(givenName: "Tim"))
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "  \n  ")

        XCTAssertEqual(
            sender,
            MessagesSender(identifier: "", displayName: "", avatarData: nil)
        )
        XCTAssertTrue(store.requestedIdentifiers.isEmpty)
    }

    func testSenderReturnsFallbackWhenContactsAccessIsNotAuthorized() {
        let store = FakeMessagesContactStore(authorizationStatus: .denied, contact: makeContact(givenName: "Tim"))
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "  +123456789  ")

        XCTAssertEqual(
            sender,
            MessagesSender(identifier: "+123456789", displayName: "+123456789", avatarData: nil)
        )
        XCTAssertTrue(store.requestedIdentifiers.isEmpty)
    }

    func testSenderUsesContactNameAndAvatar() {
        let avatarData = Data([1, 2, 3])
        let contact = makeContact(givenName: "Tim", avatarData: avatarData)
        let store = FakeMessagesContactStore(contact: contact)
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "  +123456789  ")

        XCTAssertEqual(sender.identifier, "+123456789")
        XCTAssertEqual(sender.displayName, "Tim")
        XCTAssertEqual(sender.avatarData, avatarData)
        XCTAssertTrue(sender.isKnownContact)
        XCTAssertEqual(store.requestedIdentifiers, ["+123456789"])
    }

    func testSenderUsesOrganizationWhenContactNameIsEmpty() {
        let contact = makeContact(organizationName: "  Apple  ")
        let store = FakeMessagesContactStore(contact: contact)
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "+123456789")

        XCTAssertEqual(sender.displayName, "Apple")
        XCTAssertTrue(sender.isKnownContact)
    }

    func testSenderUsesIdentifierWhenKnownContactHasNoName() {
        let store = FakeMessagesContactStore(contact: makeContact())
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "+123456789")

        XCTAssertEqual(sender.displayName, "+123456789")
        XCTAssertTrue(sender.isKnownContact)
    }

    func testSenderReturnsUnknownFallbackWhenContactIsNotFound() {
        let store = FakeMessagesContactStore(contact: nil)
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "+123456789")

        XCTAssertEqual(
            sender,
            MessagesSender(identifier: "+123456789", displayName: "+123456789", avatarData: nil)
        )
        XCTAssertFalse(sender.isKnownContact)
        XCTAssertEqual(store.requestedIdentifiers, ["+123456789"])
    }

    func testSenderReturnsFallbackWhenContactLookupFails() {
        let store = FakeMessagesContactStore(result: .failure(MessagesContactStoreError.lookupFailed))
        let resolver = MessagesContactResolver(contactStore: store)

        let sender = resolver.sender(for: "+123456789")

        XCTAssertEqual(
            sender,
            MessagesSender(identifier: "+123456789", displayName: "+123456789", avatarData: nil)
        )
        XCTAssertFalse(sender.isKnownContact)
    }

    func testSenderCachesResolvedContactCaseInsensitively() {
        let store = FakeMessagesContactStore(contact: makeContact(givenName: "Tim"))
        let resolver = MessagesContactResolver(contactStore: store)

        let firstSender = resolver.sender(for: "USER@example.com")
        let secondSender = resolver.sender(for: "user@example.com")

        XCTAssertEqual(firstSender, secondSender)
        XCTAssertEqual(store.requestedIdentifiers, ["USER@example.com"])
    }

    func testUnknownFallbackIsNotCached() {
        let store = FakeMessagesContactStore(contact: nil)
        let resolver = MessagesContactResolver(contactStore: store)

        let firstSender = resolver.sender(for: "+123456789")

        store.result = .success(makeContact(givenName: "Tim"))

        let secondSender = resolver.sender(for: "+123456789")

        XCTAssertFalse(firstSender.isKnownContact)
        XCTAssertTrue(secondSender.isKnownContact)
        XCTAssertEqual(secondSender.displayName, "Tim")
        XCTAssertEqual(store.requestedIdentifiers, ["+123456789", "+123456789"])
    }

    func testSenderCanResolveContactAfterAuthorizationChanges() {
        let store = FakeMessagesContactStore(authorizationStatus: .denied, contact: makeContact(givenName: "Tim"))
        let resolver = MessagesContactResolver(contactStore: store)

        let unauthorizedSender = resolver.sender(for: "+123456789")

        store.authorizationStatus = .authorized

        let authorizedSender = resolver.sender(for: "+123456789")

        XCTAssertFalse(unauthorizedSender.isKnownContact)
        XCTAssertTrue(authorizedSender.isKnownContact)
        XCTAssertEqual(authorizedSender.displayName, "Tim")
        XCTAssertEqual(store.requestedIdentifiers, ["+123456789"])
    }

    private func makeContact(givenName: String = "", organizationName: String = "", avatarData: Data? = nil) -> CNContact {
        let contact = TestMessagesContact()

        contact.givenName = givenName
        contact.organizationName = organizationName
        contact.storedThumbnailImageData = avatarData

        return contact
    }
}

private final class FakeMessagesContactStore: MessagesContactStoring {
    var authorizationStatus: CNAuthorizationStatus
    var result: Result<CNContact?, Error>

    private(set) var requestedIdentifiers: [String] = []

    init(authorizationStatus: CNAuthorizationStatus = .authorized, contact: CNContact?) {
        self.authorizationStatus = authorizationStatus
        self.result = .success(contact)
    }

    init(authorizationStatus: CNAuthorizationStatus = .authorized, result: Result<CNContact?, Error>) {
        self.authorizationStatus = authorizationStatus
        self.result = result
    }

    func contact(matching identifier: String) throws -> CNContact? {
        requestedIdentifiers.append(identifier)

        return try result.get()
    }
}

private enum MessagesContactStoreError: Error {
    case lookupFailed
}

private final class TestMessagesContact: CNMutableContact {
    var storedThumbnailImageData: Data?

    override var thumbnailImageData: Data? {
        storedThumbnailImageData
    }
}
