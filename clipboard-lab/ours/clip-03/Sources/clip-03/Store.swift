import AppKit
import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum ClipKind: String {
    case text
    case image
    case url
}

struct ClipDraft {
    let createdAt: Date
    let sourceApp: String?
    let kind: ClipKind
    let searchableText: String
    let textValue: String?
    let payload: Data?
    let payloadBytes: Int
    let imageWidth: Int?
    let imageHeight: Int?
}

struct ClipRecord {
    let id: String
    let createdAt: Date
    let sourceApp: String?
    let kind: ClipKind
    let searchableText: String
    let textValue: String?
    let payload: Data?
    let payloadBytes: Int
    let imageWidth: Int?
    let imageHeight: Int?

    var titleText: String {
        switch kind {
        case .text:
            let raw = textValue ?? searchableText
            let collapsed = raw
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return collapsed.isEmpty ? "Empty Text Clip" : String(collapsed.prefix(140))
        case .url:
            return textValue ?? "URL Clip"
        case .image:
            if let imageWidth, let imageHeight {
                return "Image \(imageWidth)x\(imageHeight)"
            }
            return "Image Clip"
        }
    }

    var detailText: String {
        var parts: [String] = []
        if let sourceApp, !sourceApp.isEmpty {
            parts.append(sourceApp)
        }
        parts.append(createdAt.formatted(date: .abbreviated, time: .shortened))

        switch kind {
        case .image:
            if let imageWidth, let imageHeight {
                parts.append("\(imageWidth)x\(imageHeight)")
            }
            parts.append(ByteCountFormatter.string(fromByteCount: Int64(payloadBytes), countStyle: .file))
        case .url:
            parts.append("URL")
        case .text:
            break
        }

        return parts.joined(separator: "  •  ")
    }

    var previewImage: NSImage? {
        guard kind == .image, let payload else {
            return nil
        }
        return NSImage(data: payload)
    }
}

struct SearchResult {
    let records: [ClipRecord]
    let error: String?
}

enum StoreError: Error {
    case pathResolutionFailed
    case databaseOpenFailed(message: String)
    case statementPreparationFailed(message: String)
    case executionFailed(message: String)
    case permissionsMismatch(path: String)
}

final class Store {
    private let maxEntries: Int
    private let db: OpaquePointer
    private let databaseURL: URL

    init(maxEntries: Int = 200, fileManager: FileManager = .default) throws {
        self.maxEntries = maxEntries

        guard let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StoreError.pathResolutionFailed
        }

        let directoryURL = supportRoot.appendingPathComponent("clip-03", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        databaseURL = directoryURL.appendingPathComponent("history.sqlite", isDirectory: false)

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(databaseURL.path, &handle, flags, nil) != SQLITE_OK || handle == nil {
            let message = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown sqlite error"
            if let handle {
                sqlite3_close(handle)
            }
            throw StoreError.databaseOpenFailed(message: message)
        }

        db = handle!
        sqlite3_busy_timeout(db, 250)

        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: databaseURL.path)
        try verifyPermissions(fileManager: fileManager)

        try execute("""
        CREATE TABLE IF NOT EXISTS history (
            id TEXT PRIMARY KEY,
            created_at REAL NOT NULL,
            source_app TEXT,
            kind TEXT NOT NULL,
            searchable_text TEXT NOT NULL,
            text_value TEXT,
            payload BLOB,
            payload_bytes INTEGER NOT NULL,
            image_width INTEGER,
            image_height INTEGER
        );
        """)

        try execute("""
        CREATE INDEX IF NOT EXISTS history_created_at_idx
        ON history(created_at DESC);
        """)

        try execute("""
        CREATE INDEX IF NOT EXISTS history_source_app_idx
        ON history(source_app);
        """)

        try execute("""
        CREATE INDEX IF NOT EXISTS history_kind_idx
        ON history(kind);
        """)
    }

    deinit {
        sqlite3_close(db)
    }

    func fetchEntries(search: String?) -> SearchResult {
        let parsedQuery: QueryParser.ParsedQuery

        do {
            parsedQuery = try QueryParser.parse(search)
        } catch let error as QueryParser.ParseError {
            return SearchResult(records: [], error: error.userMessage)
        } catch {
            return SearchResult(records: [], error: "Search query is invalid.")
        }

        let sql = """
        SELECT id, created_at, source_app, kind, searchable_text, text_value, payload, payload_bytes, image_width, image_height
        FROM history
        \(parsedQuery.sqlWhereClause)
        ORDER BY created_at DESC
        LIMIT ?;
        """

        do {
            let records = try withStatement(sql) { statement in
                var index: Int32 = 1
                for binding in parsedQuery.bindings {
                    bind(queryValue: binding, to: statement, index: index)
                    index += 1
                }

                sqlite3_bind_int(statement, index, Int32(maxEntries))

                var rows: [ClipRecord] = []
                while sqlite3_step(statement) == SQLITE_ROW {
                    rows.append(record(from: statement))
                }
                return rows
            }
            return SearchResult(records: records, error: nil)
        } catch {
            return SearchResult(records: [], error: "Search failed.")
        }
    }

    func save(_ draft: ClipDraft) throws -> ClipRecord? {
        if let latest = try latestRecord(),
           latest.kind == draft.kind,
           latest.textValue == draft.textValue,
           latest.payload == draft.payload {
            return nil
        }

        let record = ClipRecord(
            id: UUID().uuidString,
            createdAt: draft.createdAt,
            sourceApp: draft.sourceApp,
            kind: draft.kind,
            searchableText: draft.searchableText,
            textValue: draft.textValue,
            payload: draft.payload,
            payloadBytes: draft.payloadBytes,
            imageWidth: draft.imageWidth,
            imageHeight: draft.imageHeight
        )

        try withStatement("""
        INSERT INTO history (
            id,
            created_at,
            source_app,
            kind,
            searchable_text,
            text_value,
            payload,
            payload_bytes,
            image_width,
            image_height
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """) { statement in
            sqlite3_bind_text(statement, 1, record.id, -1, sqliteTransient)
            sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
            bind(optionalText: record.sourceApp, to: statement, index: 3)
            sqlite3_bind_text(statement, 4, record.kind.rawValue, -1, sqliteTransient)
            sqlite3_bind_text(statement, 5, record.searchableText, -1, sqliteTransient)
            bind(optionalText: record.textValue, to: statement, index: 6)
            bind(optionalData: record.payload, to: statement, index: 7)
            sqlite3_bind_int64(statement, 8, sqlite3_int64(record.payloadBytes))
            bind(optionalInt: record.imageWidth, to: statement, index: 9)
            bind(optionalInt: record.imageHeight, to: statement, index: 10)
            try step(statement)
        }

        try trimOverflow()
        return record
    }

    func databasePath() -> String {
        databaseURL.path
    }

    private func latestRecord() throws -> ClipRecord? {
        try withStatement("""
        SELECT id, created_at, source_app, kind, searchable_text, text_value, payload, payload_bytes, image_width, image_height
        FROM history
        ORDER BY created_at DESC
        LIMIT 1;
        """) { statement in
            guard sqlite3_step(statement) == SQLITE_ROW else {
                return nil
            }
            return record(from: statement)
        }
    }

    private func trimOverflow() throws {
        try withStatement("""
        DELETE FROM history
        WHERE id NOT IN (
            SELECT id FROM history
            ORDER BY created_at DESC
            LIMIT ?
        );
        """) { statement in
            sqlite3_bind_int(statement, 1, Int32(maxEntries))
            try step(statement)
        }
    }

    private func verifyPermissions(fileManager: FileManager) throws {
        let attributes = try fileManager.attributesOfItem(atPath: databaseURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        guard permissions?.intValue == 0o600 else {
            throw StoreError.permissionsMismatch(path: databaseURL.path)
        }
    }

    private func record(from statement: OpaquePointer?) -> ClipRecord {
        let id = stringColumn(statement, index: 0) ?? UUID().uuidString
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
        let sourceApp = stringColumn(statement, index: 2)
        let kind = ClipKind(rawValue: stringColumn(statement, index: 3) ?? "") ?? .text
        let searchableText = stringColumn(statement, index: 4) ?? ""
        let textValue = stringColumn(statement, index: 5)
        let payload = dataColumn(statement, index: 6)
        let payloadBytes = Int(sqlite3_column_int64(statement, 7))
        let imageWidth = intColumn(statement, index: 8)
        let imageHeight = intColumn(statement, index: 9)

        return ClipRecord(
            id: id,
            createdAt: createdAt,
            sourceApp: sourceApp,
            kind: kind,
            searchableText: searchableText,
            textValue: textValue,
            payload: payload,
            payloadBytes: payloadBytes,
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
    }

    private func execute(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorPointer) != SQLITE_OK {
            let message = errorPointer.map { String(cString: $0) } ?? "sqlite exec failed"
            sqlite3_free(errorPointer)
            throw StoreError.executionFailed(message: message)
        }
    }

    private func withStatement<T>(_ sql: String, _ body: (OpaquePointer?) throws -> T) throws -> T {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw StoreError.statementPreparationFailed(message: String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func step(_ statement: OpaquePointer?) throws {
        if sqlite3_step(statement) != SQLITE_DONE {
            throw StoreError.executionFailed(message: String(cString: sqlite3_errmsg(db)))
        }
    }

    private func bind(optionalText value: String?, to statement: OpaquePointer?, index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(statement, index, value, -1, sqliteTransient)
    }

    private func bind(queryValue value: QueryParser.BoundValue, to statement: OpaquePointer?, index: Int32) {
        switch value {
        case .string(let string):
            sqlite3_bind_text(statement, index, string, -1, sqliteTransient)
        case .double(let number):
            sqlite3_bind_double(statement, index, number)
        }
    }

    private func bind(optionalData value: Data?, to statement: OpaquePointer?, index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        _ = value.withUnsafeBytes { buffer in
            if let pointer = buffer.baseAddress {
                sqlite3_bind_blob(statement, index, pointer, Int32(value.count), sqliteTransient)
            } else {
                sqlite3_bind_blob(statement, index, nil, 0, sqliteTransient)
            }
        }
    }

    private func bind(optionalInt value: Int?, to statement: OpaquePointer?, index: Int32) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_int64(statement, index, sqlite3_int64(value))
    }

    private func stringColumn(_ statement: OpaquePointer?, index: Int32) -> String? {
        guard let raw = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: raw)
    }

    private func dataColumn(_ statement: OpaquePointer?, index: Int32) -> Data? {
        let count = Int(sqlite3_column_bytes(statement, index))
        guard count > 0, let bytes = sqlite3_column_blob(statement, index) else {
            return nil
        }
        return Data(bytes: bytes, count: count)
    }

    private func intColumn(_ statement: OpaquePointer?, index: Int32) -> Int? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else {
            return nil
        }
        return Int(sqlite3_column_int64(statement, index))
    }
}
