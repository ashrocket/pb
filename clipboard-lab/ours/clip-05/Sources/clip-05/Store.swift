import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum ClipKind: String, Sendable {
    case text
    case image
    case url
}

struct ClipDraft: Sendable {
    let createdAt: Date
    let sourceApp: String?
    let kind: ClipKind
    let searchablePlaintext: String
    let displayText: String?
    let payload: Data?
    let payloadBytes: Int
    let imageWidth: Int?
    let imageHeight: Int?

    var plaintextPayload: Data? {
        switch kind {
        case .text, .url:
            return displayText?.data(using: .utf8)
        case .image:
            return payload
        }
    }
}

struct ClipRecord: Sendable {
    let id: String
    let createdAt: Date
    let sourceApp: String?
    let kind: ClipKind
    let displayText: String?
    let payload: Data?
    let payloadBytes: Int
    let imageWidth: Int?
    let imageHeight: Int?
    let recognizedText: String?
    let isEncrypted: Bool

    var titleText: String {
        switch kind {
        case .text:
            let raw = displayText ?? ""
            let collapsed = raw
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return collapsed.isEmpty ? "Empty Text Clip" : String(collapsed.prefix(160))
        case .url:
            return displayText ?? "URL Clip"
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
            if let recognizedText, !recognizedText.isEmpty {
                parts.append("OCR")
            }
        case .url:
            parts.append("URL")
        case .text:
            break
        }

        if isEncrypted {
            parts.append("Encrypted")
        }

        return parts.joined(separator: "  •  ")
    }
}

struct SearchPageResult: Sendable {
    let records: [ClipRecord]
    let error: String?
    let hasMore: Bool
}

enum StoreError: Error {
    case pathResolutionFailed
    case databaseOpenFailed(message: String)
    case decryptionFailed
    case statementPreparationFailed(message: String)
    case executionFailed(message: String)
    case permissionsMismatch(path: String)
}

final class Store: @unchecked Sendable {
    private var maxEntries: Int
    private let db: OpaquePointer
    private let databaseURL: URL
    private let encryptionManager: EncryptionManager

    init(
        configuration: ClipConfiguration,
        encryptionManager: EncryptionManager,
        fileManager: FileManager = .default,
        supportDirectoryURL: URL? = nil
    ) throws {
        self.maxEntries = configuration.historyRetentionCount
        self.encryptionManager = encryptionManager

        if let supportDirectoryURL {
            databaseURL = supportDirectoryURL.appendingPathComponent("history.sqlite", isDirectory: false)
            try fileManager.createDirectory(at: supportDirectoryURL, withIntermediateDirectories: true)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: supportDirectoryURL.path)
        } else {
            guard let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw StoreError.pathResolutionFailed
            }

            let directoryURL = supportRoot.appendingPathComponent("clip-05", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)
            databaseURL = directoryURL.appendingPathComponent("history.sqlite", isDirectory: false)
        }

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
        try execute("PRAGMA foreign_keys = ON;")
        try execute("PRAGMA journal_mode = WAL;")

        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: databaseURL.path)
        try verifyPermissions(fileManager: fileManager)

        try execute("""
        CREATE TABLE IF NOT EXISTS history (
            id TEXT PRIMARY KEY,
            created_at REAL NOT NULL,
            source_app TEXT,
            kind TEXT NOT NULL,
            payload BLOB NOT NULL,
            payload_bytes INTEGER NOT NULL,
            image_width INTEGER,
            image_height INTEGER,
            metadata_payload BLOB,
            is_encrypted INTEGER NOT NULL DEFAULT 1
        );
        """)

        try execute("""
        CREATE TABLE IF NOT EXISTS search_terms (
            clip_id TEXT NOT NULL,
            prefix_hash BLOB NOT NULL,
            PRIMARY KEY (clip_id, prefix_hash),
            FOREIGN KEY (clip_id) REFERENCES history(id) ON DELETE CASCADE
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

        try execute("""
        CREATE INDEX IF NOT EXISTS history_encrypted_idx
        ON history(is_encrypted);
        """)

        try execute("""
        CREATE INDEX IF NOT EXISTS search_terms_prefix_idx
        ON search_terms(prefix_hash);
        """)

        try trimOverflow()
    }

    deinit {
        sqlite3_close(db)
    }

    func applyConfiguration(_ configuration: ClipConfiguration) {
        maxEntries = max(1, configuration.historyRetentionCount)
        try? trimOverflow()
    }

    func fetchPage(search: String?, offset: Int, limit: Int) -> SearchPageResult {
        let parsedQuery: QueryParser.ParsedQuery

        do {
            parsedQuery = try QueryParser.parse(search)
        } catch let error as QueryParser.ParseError {
            return SearchPageResult(records: [], error: error.userMessage, hasMore: false)
        } catch {
            return SearchPageResult(records: [], error: "Search query is invalid.", hasMore: false)
        }

        do {
            let records = try fetchRecords(parsedQuery: parsedQuery, offset: max(0, offset), limit: max(1, limit))
            let hasMore = records.count > limit
            return SearchPageResult(records: Array(records.prefix(limit)), error: nil, hasMore: hasMore)
        } catch StoreError.decryptionFailed {
            return SearchPageResult(records: [], error: "Encrypted history could not be decrypted.", hasMore: false)
        } catch {
            return SearchPageResult(records: [], error: "Search failed.", hasMore: false)
        }
    }

    func save(_ draft: ClipDraft) throws -> ClipRecord? {
        if let latest = try latestRecord(),
           latest.kind == draft.kind,
           latest.displayText == draft.displayText,
           latest.payload == draft.payload {
            return nil
        }

        guard let plaintextPayload = draft.plaintextPayload else {
            return nil
        }

        let record = ClipRecord(
            id: UUID().uuidString,
            createdAt: draft.createdAt,
            sourceApp: draft.sourceApp,
            kind: draft.kind,
            displayText: draft.displayText,
            payload: draft.payload,
            payloadBytes: draft.payloadBytes,
            imageWidth: draft.imageWidth,
            imageHeight: draft.imageHeight,
            recognizedText: nil,
            isEncrypted: true
        )

        let ciphertext = try encryptionManager.encrypt(plaintextPayload)
        let prefixHashes = try hashedPrefixes(for: draft.searchablePlaintext)

        try withStatement("""
        INSERT INTO history (
            id,
            created_at,
            source_app,
            kind,
            payload,
            payload_bytes,
            image_width,
            image_height,
            metadata_payload,
            is_encrypted
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """) { statement in
            sqlite3_bind_text(statement, 1, record.id, -1, sqliteTransient)
            sqlite3_bind_double(statement, 2, record.createdAt.timeIntervalSince1970)
            bind(optionalText: record.sourceApp, to: statement, index: 3)
            sqlite3_bind_text(statement, 4, record.kind.rawValue, -1, sqliteTransient)
            bind(data: ciphertext, to: statement, index: 5)
            sqlite3_bind_int64(statement, 6, sqlite3_int64(record.payloadBytes))
            bind(optionalInt: record.imageWidth, to: statement, index: 7)
            bind(optionalInt: record.imageHeight, to: statement, index: 8)
            sqlite3_bind_null(statement, 9)
            sqlite3_bind_int(statement, 10, 1)
            try step(statement)
        }

        try replaceSearchTerms(clipID: record.id, prefixHashes: prefixHashes)
        try trimOverflow()
        return record
    }

    func updateRecognizedText(_ text: String, forClipID clipID: String) throws {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let encryptedMetadata = normalized.isEmpty ? nil : try encryptionManager.encrypt(Data(normalized.utf8))

        try withStatement("""
        UPDATE history
        SET metadata_payload = ?
        WHERE id = ? AND kind = ?;
        """) { statement in
            if let encryptedMetadata {
                bind(data: encryptedMetadata, to: statement, index: 1)
            } else {
                sqlite3_bind_null(statement, 1)
            }
            sqlite3_bind_text(statement, 2, clipID, -1, sqliteTransient)
            sqlite3_bind_text(statement, 3, ClipKind.image.rawValue, -1, sqliteTransient)
            try step(statement)
        }

        let prefixHashes = try hashedPrefixes(for: normalized)
        try replaceSearchTerms(clipID: clipID, prefixHashes: prefixHashes)
    }

    func databasePath() -> String {
        databaseURL.path
    }

    private func fetchRecords(parsedQuery: QueryParser.ParsedQuery, offset: Int, limit: Int) throws -> [ClipRecord] {
        var clauses = parsedQuery.clauses
        for index in parsedQuery.textTerms.indices {
            clauses.append("""
            EXISTS (
                SELECT 1 FROM search_terms st\(index)
                WHERE st\(index).clip_id = history.id
                  AND st\(index).prefix_hash = ?
            )
            """)
        }

        let whereClause = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = """
        SELECT id, created_at, source_app, kind, payload, payload_bytes, image_width, image_height, metadata_payload, is_encrypted
        FROM history
        \(whereClause)
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?;
        """

        return try withStatement(sql) { statement in
            var index: Int32 = 1

            for binding in parsedQuery.bindings {
                bind(queryValue: binding, to: statement, index: index)
                index += 1
            }

            for term in parsedQuery.textTerms {
                bind(data: try encryptionManager.searchDigest(for: term), to: statement, index: index)
                index += 1
            }

            sqlite3_bind_int(statement, index, Int32(limit + 1))
            sqlite3_bind_int(statement, index + 1, Int32(offset))

            var rows: [ClipRecord] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                rows.append(try record(from: statement))
            }
            return rows
        }
    }

    private func latestRecord() throws -> ClipRecord? {
        try withStatement("""
        SELECT id, created_at, source_app, kind, payload, payload_bytes, image_width, image_height, metadata_payload, is_encrypted
        FROM history
        ORDER BY created_at DESC
        LIMIT 1;
        """) { statement in
            guard sqlite3_step(statement) == SQLITE_ROW else {
                return nil
            }
            return try record(from: statement)
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

    private func replaceSearchTerms(clipID: String, prefixHashes: [Data]) throws {
        try withStatement("DELETE FROM search_terms WHERE clip_id = ?;") { statement in
            sqlite3_bind_text(statement, 1, clipID, -1, sqliteTransient)
            try step(statement)
        }

        guard !prefixHashes.isEmpty else {
            return
        }

        try withStatement("""
        INSERT OR IGNORE INTO search_terms (clip_id, prefix_hash)
        VALUES (?, ?);
        """) { statement in
            for prefixHash in prefixHashes {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)
                sqlite3_bind_text(statement, 1, clipID, -1, sqliteTransient)
                bind(data: prefixHash, to: statement, index: 2)
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw StoreError.executionFailed(message: String(cString: sqlite3_errmsg(db)))
                }
            }
        }
    }

    private func hashedPrefixes(for plaintext: String) throws -> [Data] {
        try SearchIndex.prefixes(for: plaintext).map { try encryptionManager.searchDigest(for: $0) }
    }

    private func verifyPermissions(fileManager: FileManager) throws {
        let attributes = try fileManager.attributesOfItem(atPath: databaseURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        guard permissions?.intValue == 0o600 else {
            throw StoreError.permissionsMismatch(path: databaseURL.path)
        }
    }

    private func record(from statement: OpaquePointer?) throws -> ClipRecord {
        let id = stringColumn(statement, index: 0) ?? UUID().uuidString
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
        let sourceApp = stringColumn(statement, index: 2)
        let kind = ClipKind(rawValue: stringColumn(statement, index: 3) ?? "") ?? .text
        let encryptedPayload = dataColumn(statement, index: 4) ?? Data()
        let payloadBytes = Int(sqlite3_column_int64(statement, 5))
        let imageWidth = intColumn(statement, index: 6)
        let imageHeight = intColumn(statement, index: 7)
        let encryptedMetadata = dataColumn(statement, index: 8)
        let isEncrypted = sqlite3_column_int(statement, 9) != 0

        let plaintext: Data
        if isEncrypted {
            do {
                plaintext = try encryptionManager.decrypt(encryptedPayload)
            } catch {
                throw StoreError.decryptionFailed
            }
        } else {
            plaintext = encryptedPayload
        }

        let recognizedText: String?
        if let encryptedMetadata, !encryptedMetadata.isEmpty {
            let decrypted = try encryptionManager.decrypt(encryptedMetadata)
            recognizedText = String(data: decrypted, encoding: .utf8)
        } else {
            recognizedText = nil
        }

        let displayText: String?
        let payload: Data?
        switch kind {
        case .text, .url:
            displayText = String(data: plaintext, encoding: .utf8)
            payload = nil
        case .image:
            displayText = nil
            payload = plaintext
        }

        return ClipRecord(
            id: id,
            createdAt: createdAt,
            sourceApp: sourceApp,
            kind: kind,
            displayText: displayText,
            payload: payload,
            payloadBytes: payloadBytes,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            recognizedText: recognizedText,
            isEncrypted: isEncrypted
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
        case .int(let number):
            sqlite3_bind_int(statement, index, number)
        }
    }

    private func bind(data value: Data, to statement: OpaquePointer?, index: Int32) {
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
