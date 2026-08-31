import Foundation

struct MessagesSender: Equatable, Identifiable, Sendable {
    let identifier: String
    let displayName: String
    let avatarData: Data?
    let isKnownContact: Bool

    init(
        identifier: String,
        displayName: String,
        avatarData: Data?,
        isKnownContact: Bool = false
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.avatarData = avatarData
        self.isKnownContact = isKnownContact
    }

    var id: String {
        identifier
    }
}

#if DEBUG
extension MessagesSender {
    static let debugContact = MessagesSender(
        identifier: "+79101234567",
        displayName: "Tim Cook",
        avatarData: nil,
        isKnownContact: true
    )

    static let debugUnknown = MessagesSender(identifier: "+79999999999", displayName: "+79999999999", avatarData: nil)
}
#endif
