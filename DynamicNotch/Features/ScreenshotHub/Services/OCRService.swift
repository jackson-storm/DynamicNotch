internal import AppKit
internal import Vision

final class OCRService: Sendable {
    static let shared = OCRService()
    
    private init() {}
    
    /// Recognizes text in the image file at `url`. Vision reads and decodes the file off the caller's actor.
    func recognizeText(at url: URL, languages: [String] = ["ru-RU", "en-US"]) async -> String {
        await Task.detached(priority: .utility) {
            Self.recognizeText(with: VNImageRequestHandler(url: url, options: [:]), languages: languages)
        }.value
    }
    
    /// Recognizes text from an NSImage asynchronously using Apple's Vision framework.
    func recognizeText(in image: NSImage, languages: [String] = ["ru-RU", "en-US"]) async -> String {
        await Task.detached(priority: .utility) {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return ""
            }
            return Self.recognizeText(with: VNImageRequestHandler(cgImage: cgImage, options: [:]), languages: languages)
        }.value
    }
    
    nonisolated private static func recognizeText(with handler: VNImageRequestHandler, languages: [String]) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        
        do {
            try handler.perform([request])
            guard let observations = request.results else {
                return ""
            }
            
            let recognizedLines = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            return recognizedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return ""
        }
    }
}
