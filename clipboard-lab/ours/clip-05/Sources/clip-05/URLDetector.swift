import Foundation

enum URLDetector {
    struct Match: Equatable {
        let text: String
        let url: URL
    }

    private static let detector: NSDataDetector? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    static func detectStandaloneURL(in text: String) -> Match? {
        guard let detector else {
            return nil
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: nsRange)
        guard matches.count == 1,
              let match = matches.first,
              let url = match.url,
              let matchedRange = Range(match.range, in: text),
              matchedRange == text.startIndex..<text.endIndex else {
            return nil
        }

        return Match(text: String(text[matchedRange]), url: url)
    }
}
