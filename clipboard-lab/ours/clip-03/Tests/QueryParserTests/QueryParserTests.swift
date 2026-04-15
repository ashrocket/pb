@testable import Clip03App

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

private enum QueryParserHarness {
    static func run() {
        do {
            let empty = try QueryParser.parse(nil)
            expect(empty.clauses == [], "empty query clauses mismatch")
            expect(empty.bindings == [], "empty query bindings mismatch")

            let substring = try QueryParser.parse("invoice")
            expect(substring.clauses == ["LOWER(searchable_text) LIKE LOWER(?)"], "substring clause mismatch")
            expect(substring.bindings == [.string("%invoice%")], "substring binding mismatch")

            let multiple = try QueryParser.parse("prior auth")
            expect(multiple.clauses == [
                "LOWER(searchable_text) LIKE LOWER(?)",
                "LOWER(searchable_text) LIKE LOWER(?)"
            ], "multiple substring clauses mismatch")
            expect(multiple.bindings == [.string("%prior%"), .string("%auth%")], "multiple substring bindings mismatch")

            let quoted = try QueryParser.parse("\"prior auth\"")
            expect(quoted.bindings == [.string("%prior auth%")], "quoted phrase binding mismatch")

            let appFilter = try QueryParser.parse("app:com.apple.Safari")
            expect(appFilter.clauses == ["source_app = ?"], "app filter clause mismatch")
            expect(appFilter.bindings == [.string("com.apple.Safari")], "app filter binding mismatch")

            let typeFilter = try QueryParser.parse("type:url portal")
            expect(typeFilter.clauses == ["kind = ?", "LOWER(searchable_text) LIKE LOWER(?)"], "type filter clauses mismatch")
            expect(typeFilter.bindings == [.string("url"), .string("%portal%")], "type filter bindings mismatch")

            let imageAlias = try QueryParser.parse("image: receipt")
            expect(imageAlias.clauses == ["kind = ?", "LOWER(searchable_text) LIKE LOWER(?)"], "image alias clauses mismatch")
            expect(imageAlias.bindings == [.string("image"), .string("%receipt%")], "image alias bindings mismatch")

            let inlineImageAlias = try QueryParser.parse("image:receipt")
            expect(inlineImageAlias.clauses == ["kind = ?", "LOWER(searchable_text) LIKE LOWER(?)"], "inline image alias clauses mismatch")
            expect(inlineImageAlias.bindings == [.string("image"), .string("%receipt%")], "inline image alias bindings mismatch")

            let dateOnly = try QueryParser.parse("after:2026-04-01")
            expect(dateOnly.clauses == ["created_at >= ?"], "date-only clause mismatch")
            expect(dateOnly.bindings == [.double(1_775_001_600)], "date-only binding mismatch")

            let timestamp = try QueryParser.parse("after:2026-04-01T15:30:00Z")
            expect(timestamp.clauses == ["created_at >= ?"], "timestamp clause mismatch")
            expect(timestamp.bindings == [.double(1_775_057_400)], "timestamp binding mismatch")

            let combined = try QueryParser.parse("app:com.apple.Safari type:text after:2026-04-01 portal")
            expect(combined.clauses == [
                "source_app = ?",
                "kind = ?",
                "created_at >= ?",
                "LOWER(searchable_text) LIKE LOWER(?)"
            ], "combined query clauses mismatch")
            expect(combined.bindings == [
                .string("com.apple.Safari"),
                .string("text"),
                .double(1_775_001_600),
                .string("%portal%")
            ], "combined query bindings mismatch")

            do {
                _ = try QueryParser.parse("type:file")
                fatalError("invalid type did not throw")
            } catch let error as QueryParser.ParseError {
                expect(error == .invalidType("file"), "invalid type error mismatch")
            }

            do {
                _ = try QueryParser.parse("after:not-a-date")
                fatalError("invalid after did not throw")
            } catch let error as QueryParser.ParseError {
                expect(error == .invalidDate("not-a-date"), "invalid after error mismatch")
            }
        } catch {
            fatalError("unexpected harness error: \(error)")
        }
    }
}

private let queryParserHarnessDidRun: Void = {
    QueryParserHarness.run()
}()
