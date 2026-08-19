import Foundation

struct MailMessage: Equatable {
    let rowID: Int64
    let messageIDHeader: String
    let sender: String
    let subject: String
    let summary: String?
    let receivedDate: Date
}

#if DEBUG
extension MailMessage {
    static let debugPreview = debugPreviewStandard

    static let debugPreviewStandard = MailMessage(
        rowID: -1,
        messageIDHeader: "<debug-standard@mail.preview>",
        sender: "John Appleseed <john@apple.com>",
        subject: "Project Roadmap Update",
        summary: "Hey team, please review the attached design specifications for the upcoming notch release.",
        receivedDate: Date()
    )

    static let debugPreviewNoSummary = MailMessage(
        rowID: -2,
        messageIDHeader: "<debug-no-summary@mail.preview>",
        sender: "App Store <no-reply@apple.com>",
        subject: "Your invoice is ready",
        summary: nil,
        receivedDate: Date()
    )

    static let debugPreviewNoSubject = MailMessage(
        rowID: -3,
        messageIDHeader: "<debug-no-subject@mail.preview>",
        sender: "Sarah Connor <sarah@sky.net>",
        subject: "",
        summary: "Quick heads up about tomorrow's schedule and meeting notes.",
        receivedDate: Date()
    )

    static let debugPreviewNoSubjectNoSummary = MailMessage(
        rowID: -4,
        messageIDHeader: "<debug-minimal@mail.preview>",
        sender: "support@github.com",
        subject: "",
        summary: nil,
        receivedDate: Date()
    )

    static let debugPreviewLongContent = MailMessage(
        rowID: -5,
        messageIDHeader: "<debug-long@mail.preview>",
        sender: "Extremely Long Sender Name With Multiple Words <very.long.sender.email.address.test@organization.domain.com>",
        subject: "Urgent Announcement: Very Long Subject Line Exceeding Typical Width Requirements for Dynamic Notch Notifications",
        summary: "This is an extremely long email preview summary text designed to verify multiple lines wrapping, graceful font rendering, bounds protection, and truncation across standard notch and dynamic island modes.",
        receivedDate: Date()
    )
}
#endif
