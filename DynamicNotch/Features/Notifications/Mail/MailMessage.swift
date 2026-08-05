import Foundation

struct MailMessage: Equatable {
    let rowID: Int64
    let sender: String
    let subject: String
    let summary: String?
    let receivedDate: Date
}
