internal import AppKit
internal import Vision

final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Recognizes text from an NSImage asynchronously using Apple's Vision framework.
    func recognizeText(in image: NSImage, languages: [String] = ["ru-RU", "en-US"], completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedLines = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let resultText = recognizedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            completion(resultText)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion("")
                }
            }
        }
    }
}
