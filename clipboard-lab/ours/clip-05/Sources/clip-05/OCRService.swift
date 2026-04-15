import Foundation
import Vision

final class OCRService {
    private let queue = DispatchQueue(label: "local.clip05.ocr", qos: .utility)

    func recognizeText(in imageData: Data, completion: @escaping @Sendable (String?) -> Void) {
        queue.async {
            let text = Self.recognizedText(in: imageData)
            DispatchQueue.main.async {
                completion(text)
            }
        }
    }

    static func recognizedText(in imageData: Data) -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(data: imageData, options: [:])
        do {
            try handler.perform([request])
            let text = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }
}
