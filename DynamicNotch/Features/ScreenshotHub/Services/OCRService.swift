internal import AppKit
internal import Vision

final class OCRService: Sendable {
    static let shared = OCRService()
    
    private init() {}
    
    /// Recognizes text from an NSImage asynchronously using Apple's Vision framework.
    func recognizeText(in image: NSImage, languages: [String] = ["ru-RU", "en-US"]) async -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ""
        }
        
        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
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
        }.value
    }
}
