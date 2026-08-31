import Foundation

struct MailSenderInfo: Equatable, Sendable {
    let displayName: String
    let email: String?
    let avatarData: Data?
    let isKnownContact: Bool
}

enum MailSenderFormatter {
    static func format(rawSender: String, resolver: MessagesContactResolver = .shared) -> MailSenderInfo {
        let trimmed = rawSender.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MailSenderInfo(displayName: "Unknown", email: nil, avatarData: nil, isKnownContact: false)
        }

        var parsedName: String?
        var parsedEmail: String?

        if let openBracket = trimmed.range(of: "<"),
           let closeBracket = trimmed.range(of: ">", range: openBracket.upperBound..<trimmed.endIndex) {
            let emailPart = String(trimmed[openBracket.upperBound..<closeBracket.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let namePart = String(trimmed[..<openBracket.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))
            parsedEmail = emailPart.isEmpty ? nil : emailPart
            parsedName = namePart.isEmpty ? nil : namePart
        } else if trimmed.contains("@") {
            parsedEmail = trimmed
        } else {
            parsedName = trimmed
        }

        // Try contact resolution if we have an email address
        if let email = parsedEmail {
            let contact = resolver.sender(for: email)
            if contact.isKnownContact {
                return MailSenderInfo(
                    displayName: contact.displayName,
                    email: email,
                    avatarData: contact.avatarData,
                    isKnownContact: true
                )
            }
        }

        let finalName = parsedName ?? parsedEmail ?? trimmed
        return MailSenderInfo(
            displayName: finalName,
            email: parsedEmail,
            avatarData: nil,
            isKnownContact: false
        )
    }
}
