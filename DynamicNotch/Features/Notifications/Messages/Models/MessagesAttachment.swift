import Foundation

enum MessagesAttachment: Equatable, Identifiable, Sendable {
    case image(MessagesImageAttachment)
    case video(MessagesVideoAttachment)
    case audio(MessagesAudioAttachment)
    case file(MessagesFileAttachment)

    var id: String {
        switch self {
        case .image(let attachment):
            attachment.id
        case .video(let attachment):
            attachment.id
        case .audio(let attachment):
            attachment.id
        case .file(let attachment):
            attachment.id
        }
    }
}

struct MessagesImageAttachment: Equatable, Identifiable, Sendable {
    let id: String
    let fileURL: URL?
    let width: Int?
    let height: Int?
}

struct MessagesVideoAttachment: Equatable, Identifiable, Sendable {
    let id: String
    let fileURL: URL?
    let duration: TimeInterval?
}

struct MessagesAudioAttachment: Equatable, Identifiable, Sendable {
    let id: String
    let fileURL: URL?
    let duration: TimeInterval?
}

struct MessagesFileAttachment: Equatable, Identifiable, Sendable {
    let id: String
    let fileURL: URL?
    let filename: String?
    let mimeType: String?
    let uti: String?
}

#if DEBUG
extension MessagesAttachment {
    private static var debugPhotoURL: URL? {
        debugResourceURL(named: "MessagesPreviewPhoto", withExtension: "jpg")
    }

    private static var debugVideoURL: URL? {
        debugResourceURL(named: "MessagesPreviewVideo", withExtension: "mov")
    }

    private static var debugDocumentURL: URL? {
        debugResourceURL(named: "MessagesPreviewDocument", withExtension: "pdf")
    }

    private static var debugAudioURL: URL? {
        Bundle.main.url(forResource: "LowBatterySound", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "LowBatterySound", withExtension: "mp3", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: "LowBatterySound", withExtension: "mp3", subdirectory: "Resources/Sounds")
    }

    static let debugImage = debugImageAttachment(id: "debug-image")
    static let debugVideo = MessagesAttachment.video(MessagesVideoAttachment(id: "debug-video", fileURL: debugVideoURL, duration: nil))
    static let debugAudio = MessagesAttachment.audio(MessagesAudioAttachment(id: "debug-audio", fileURL: debugAudioURL, duration: nil))

    static let debugFile = MessagesAttachment.file(
        MessagesFileAttachment(
            id: "debug-file",
            fileURL: debugDocumentURL,
            filename: "MessagesPreviewDocument.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )
    )

    static func debugImageAttachment(id: String) -> MessagesAttachment {
        MessagesAttachment.image(
            MessagesImageAttachment(
                id: id,
                fileURL: debugPhotoURL,
                width: nil,
                height: nil
            )
        )
    }

    private static func debugResourceURL(named name: String, withExtension fileExtension: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Preview Content/Messages")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: "Messages")
            ?? Bundle.main.url(forResource: name, withExtension: fileExtension)
    }
}
#endif
