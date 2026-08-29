import Contacts
import Foundation
import OSLog

protocol MessagesContactStoring {
    var authorizationStatus: CNAuthorizationStatus { get }

    func contact(matching identifier: String) throws -> CNContact?
}

final class SystemMessagesContactStore: MessagesContactStoring {

    private let contactStore: CNContactStore

    init(contactStore: CNContactStore = CNContactStore()) {
        self.contactStore = contactStore
    }

    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    func contact(matching identifier: String) throws -> CNContact? {
        let predicate: NSPredicate

        if identifier.contains("@") {
            predicate = CNContact.predicateForContacts(matchingEmailAddress: identifier)
        } else {
            predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: identifier))
        }

        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]

        return try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys).first
    }
}

final class MessagesContactResolver {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesContactResolver")

    private let contactStore: any MessagesContactStoring
    private var cachedSenders: [String: MessagesSender] = [:]

    init(contactStore: any MessagesContactStoring = SystemMessagesContactStore()) {
        self.contactStore = contactStore
    }

    func sender(for identifier: String) -> MessagesSender {
        let normalizedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedIdentifier.isEmpty else {
            return fallbackSender(for: normalizedIdentifier)
        }

        guard contactStore.authorizationStatus == .authorized else {
            return fallbackSender(for: normalizedIdentifier)
        }

        let cacheKey = normalizedIdentifier.lowercased()

        if let cachedSender = cachedSenders[cacheKey] {
            return cachedSender
        }

        do {
            guard let contact = try contactStore.contact(matching: normalizedIdentifier) else {
                return fallbackSender(for: normalizedIdentifier)
            }

            let formattedName = CNContactFormatter.string(from: contact, style: .fullName)
            let displayName = nonEmpty(formattedName) ?? nonEmpty(contact.organizationName) ?? normalizedIdentifier

            let sender = MessagesSender(
                identifier: normalizedIdentifier,
                displayName: displayName,
                avatarData: contact.thumbnailImageData,
                isKnownContact: true
            )

            cachedSenders[cacheKey] = sender

            return sender
        } catch {
            logger.error("Could not resolve Messages contact: \(error.localizedDescription, privacy: .public)")
            return fallbackSender(for: normalizedIdentifier)
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }

        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return normalizedValue.isEmpty ? nil : normalizedValue
    }

    private func fallbackSender(for identifier: String) -> MessagesSender {
        MessagesSender(identifier: identifier, displayName: identifier, avatarData: nil)
    }
}
