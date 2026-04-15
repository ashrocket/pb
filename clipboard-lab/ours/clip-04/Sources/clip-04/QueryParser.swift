import Foundation

enum QueryParser {
    enum BoundValue: Equatable {
        case string(String)
        case double(Double)
        case int(Int32)
    }

    struct ParsedQuery: Equatable {
        let clauses: [String]
        let bindings: [BoundValue]

        var sqlWhereClause: String {
            clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        }
    }

    enum ParseError: Error, Equatable {
        case emptyValue(field: String)
        case invalidDate(String)
        case invalidEncrypted(String)
        case invalidType(String)

        var userMessage: String {
            switch self {
            case .emptyValue(let field):
                return "Search field '\(field)' needs a value."
            case .invalidDate(let raw):
                return "Invalid after: value '\(raw)'. Use YYYY-MM-DD or ISO-8601."
            case .invalidEncrypted(let raw):
                return "Invalid encrypted: value '\(raw)'. Use yes or no."
            case .invalidType(let raw):
                return "Invalid type: value '\(raw)'. Use text, image, or url."
            }
        }
    }

    static func parse(_ raw: String?) throws -> ParsedQuery {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            return ParsedQuery(clauses: [], bindings: [])
        }

        var clauses: [String] = []
        var bindings: [BoundValue] = []

        func append(_ clause: String, _ binding: BoundValue) {
            clauses.append(clause)
            bindings.append(binding)
        }

        func appendSubstring(_ token: String) {
            append("LOWER(searchable_text) LIKE LOWER(?)", .string("%\(token)%"))
        }

        for token in tokenize(trimmed) {
            let lowered = token.lowercased()

            if lowered == "image:" {
                append("kind = ?", .string("image"))
                continue
            }

            if lowered.hasPrefix("image:") {
                append("kind = ?", .string("image"))
                let remainder = String(token.dropFirst("image:".count))
                if !remainder.isEmpty {
                    appendSubstring(remainder)
                }
                continue
            }

            if lowered.hasPrefix("app:") {
                let value = String(token.dropFirst("app:".count))
                guard !value.isEmpty else {
                    throw ParseError.emptyValue(field: "app")
                }
                append("source_app = ?", .string(value))
                continue
            }

            if lowered.hasPrefix("after:") {
                let value = String(token.dropFirst("after:".count))
                guard !value.isEmpty else {
                    throw ParseError.emptyValue(field: "after")
                }
                guard let date = parseDate(value) else {
                    throw ParseError.invalidDate(value)
                }
                append("created_at >= ?", .double(date.timeIntervalSince1970))
                continue
            }

            if lowered.hasPrefix("encrypted:") {
                let value = String(token.dropFirst("encrypted:".count)).lowercased()
                guard !value.isEmpty else {
                    throw ParseError.emptyValue(field: "encrypted")
                }
                switch value {
                case "yes", "true":
                    append("is_encrypted = ?", .int(1))
                case "no", "false":
                    append("is_encrypted = ?", .int(0))
                default:
                    throw ParseError.invalidEncrypted(value)
                }
                continue
            }

            if lowered.hasPrefix("type:") {
                let value = String(token.dropFirst("type:".count)).lowercased()
                guard !value.isEmpty else {
                    throw ParseError.emptyValue(field: "type")
                }
                guard ["text", "image", "url"].contains(value) else {
                    throw ParseError.invalidType(value)
                }
                append("kind = ?", .string(value))
                continue
            }

            appendSubstring(token)
        }

        return ParsedQuery(clauses: clauses, bindings: bindings)
    }

    private static func tokenize(_ raw: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var insideQuotes = false

        for character in raw {
            if character == "\"" {
                insideQuotes.toggle()
                continue
            }

            if character.isWhitespace && !insideQuotes {
                if !current.isEmpty {
                    tokens.append(current)
                    current.removeAll(keepingCapacity: true)
                }
                continue
            }

            current.append(character)
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    private static func parseDate(_ raw: String) -> Date? {
        let isoFormatterWithFractionalSeconds = ISO8601DateFormatter()
        isoFormatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatterWithFractionalSeconds.timeZone = TimeZone(secondsFromGMT: 0)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .gregorian)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        if let date = isoFormatterWithFractionalSeconds.date(from: raw) {
            return date
        }
        if let date = isoFormatter.date(from: raw) {
            return date
        }
        return dateOnlyFormatter.date(from: raw)
    }
}
