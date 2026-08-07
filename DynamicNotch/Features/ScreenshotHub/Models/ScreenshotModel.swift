internal import AppKit

struct ScreenshotModel: Identifiable, Equatable {
    let id = UUID()
    let image: NSImage
    let fileURL: URL?
    let tempFileURL: URL?
    var targetDestinationURL: URL?
    let fileName: String
    var recognizedText: String
    var isRecognizing: Bool
    let timestamp: Date
    
    static func == (lhs: ScreenshotModel, rhs: ScreenshotModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.recognizedText == rhs.recognizedText &&
        lhs.isRecognizing == rhs.isRecognizing
    }
}
