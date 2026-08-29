internal import AppKit

struct ScreenRecordingResultModel: Identifiable, Equatable {
    let id = UUID()
    let fileURL: URL
    let thumbnail: NSImage
    let fileName: String
    let timestamp: Date

    static func == (lhs: ScreenRecordingResultModel, rhs: ScreenRecordingResultModel) -> Bool {
        lhs.id == rhs.id && lhs.fileURL == rhs.fileURL
    }
}
