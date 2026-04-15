import Foundation

enum SearchIndex {
    static func prefixes(for plaintext: String) -> [String] {
        Set(tokenize(plaintext).flatMap { prefixes(forToken: $0) }).sorted()
    }

    static func queryTerms(for raw: String) -> [String] {
        tokenize(raw)
    }

    static func normalizedSearchTerm(_ raw: String) -> String {
        raw
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokenize(_ raw: String) -> [String] {
        let normalized = normalizedSearchTerm(raw)
        let scalars = normalized.unicodeScalars

        var tokens: [String] = []
        var current = String.UnicodeScalarView()

        func flush() {
            guard !current.isEmpty else {
                return
            }
            let token = String(current)
            if !token.isEmpty {
                tokens.append(token)
            }
            current.removeAll(keepingCapacity: true)
        }

        for scalar in scalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.append(scalar)
            } else {
                flush()
            }
        }

        flush()
        return tokens
            .map { String($0.prefix(64)) }
            .filter { !$0.isEmpty }
    }

    private static func prefixes(forToken token: String) -> [String] {
        guard !token.isEmpty else {
            return []
        }

        let scalars = Array(token)
        let maxLength = min(scalars.count, 24)
        return (1...maxLength).map { length in
            String(scalars.prefix(length))
        }
    }
}
