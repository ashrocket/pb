import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct VerificationFailure: Error, CustomStringConvertible {
    let description: String
}

enum Clip05Verifier {
    static func main() throws {
        var count = 0

        try run("encryption round trip", counter: &count) {
            let manager = EncryptionManager(keychain: InMemoryKeychainStore())
            let plaintext = Data("prior auth packet".utf8)
            let ciphertext = try manager.encrypt(plaintext)
            try expect(ciphertext != plaintext, "ciphertext should differ from plaintext")
            try expect(ciphertext.first == 1, "ciphertext version prefix mismatch")
            let decrypted = try manager.decrypt(ciphertext)
            try expect(decrypted == plaintext, "decrypted payload mismatch")
        }

        try run("encryption rejects plaintext", counter: &count) {
            let manager = EncryptionManager(keychain: InMemoryKeychainStore())
            do {
                _ = try manager.decrypt(Data("plain".utf8))
                throw VerificationFailure(description: "plaintext unexpectedly decrypted")
            } catch EncryptionError.invalidCiphertext {
                return
            }
        }

        try run("search digest stable for same key", counter: &count) {
            let manager = EncryptionManager(keychain: InMemoryKeychainStore())
            let left = try manager.searchDigest(for: "portal")
            let right = try manager.searchDigest(for: "portal")
            try expect(left == right, "same digest mismatch")
        }

        try run("search digest differs across keys", counter: &count) {
            let left = try EncryptionManager(keychain: InMemoryKeychainStore()).searchDigest(for: "portal")
            let right = try EncryptionManager(keychain: InMemoryKeychainStore()).searchDigest(for: "portal")
            try expect(left != right, "different keychains should produce different HMACs")
        }

        try run("store search matches token prefix", counter: &count) {
            try withStore { store in
                _ = try store.save(textDraft("Portal intake packet"))
                let result = store.fetchPage(search: "port", offset: 0, limit: 20)
                try expect(result.records.count == 1, "prefix search should find token")
            }
        }

        try run("store search combines multiple terms", counter: &count) {
            try withStore { store in
                _ = try store.save(textDraft("Portal intake packet"))
                _ = try store.save(textDraft("Portal only"))
                let result = store.fetchPage(search: "portal pack", offset: 0, limit: 20)
                try expect(result.records.count == 1, "AND search mismatch")
            }
        }

        try run("store search rejects infix term", counter: &count) {
            try withStore { store in
                _ = try store.save(textDraft("Portal intake packet"))
                let result = store.fetchPage(search: "rtal", offset: 0, limit: 20)
                try expect(result.records.isEmpty, "infix search should not match")
            }
        }

        try run("store pagination loads twenty rows", counter: &count) {
            try withStore { store in
                for index in 0..<23 {
                    _ = try store.save(textDraft("record \(index)"))
                }
                let page = store.fetchPage(search: nil, offset: 0, limit: 20)
                try expect(page.records.count == 20, "pagination count mismatch")
                try expect(page.hasMore, "pagination hasMore mismatch")
            }
        }

        try run("ocr metadata becomes searchable", counter: &count) {
            try withStore { store in
                let record = try require(store.save(try imageDraft()), "missing image record")
                try store.updateRecognizedText("Invoice Number 1234", forClipID: record.id)
                let result = store.fetchPage(search: "type:image invo", offset: 0, limit: 20)
                try expect(result.records.count == 1, "OCR text search mismatch")
            }
        }

        try run("ocr update preserves encrypted image payload", counter: &count) {
            try withStore { store in
                let record = try require(store.save(try imageDraft()), "missing image record")
                try store.updateRecognizedText("Safety Plan", forClipID: record.id)
                let result = store.fetchPage(search: "type:image saf", offset: 0, limit: 20)
                try expect(result.records.first?.payload == record.payload, "payload changed after OCR")
            }
        }

        try run("config file codec round trip", counter: &count) {
            let configuration = ClipConfiguration(
                autoStartAtLogin: true,
                excludedBundleIDs: ["com.apple.Mail", "com.apple.Safari"],
                historyRetentionCount: 300,
                hotkeyModifiers: .commandOption,
                maxBytesPerClip: 4096,
                pauseCapture: true,
                pollingIntervalSeconds: 0.3
            )
            let decoded = ConfigFileCodec.decode(ConfigFileCodec.encode(configuration))
            try expect(decoded == configuration, "config round trip mismatch")
        }

        try run("query parser empty query", counter: &count) {
            let parsed = try QueryParser.parse(nil)
            try expect(parsed.clauses.isEmpty && parsed.bindings.isEmpty && parsed.textTerms.isEmpty, "empty query mismatch")
        }

        try run("query parser free term becomes encrypted term", counter: &count) {
            let parsed = try QueryParser.parse("invoice")
            try expect(parsed.textTerms == ["invoice"], "free term mismatch")
        }

        try run("query parser phrase splits into tokens", counter: &count) {
            let parsed = try QueryParser.parse("\"prior auth\"")
            try expect(parsed.textTerms == ["prior", "auth"], "phrase mismatch")
        }

        try run("query parser app filter", counter: &count) {
            let parsed = try QueryParser.parse("app:com.apple.Safari")
            try expect(parsed.clauses == ["source_app = ?"], "app clause mismatch")
            try expect(parsed.bindings == [.string("com.apple.Safari")], "app binding mismatch")
        }

        try run("query parser type and text", counter: &count) {
            let parsed = try QueryParser.parse("type:url portal")
            try expect(parsed.clauses == ["kind = ?"], "type:url clause mismatch")
            try expect(parsed.bindings == [.string("url")], "type:url binding mismatch")
            try expect(parsed.textTerms == ["portal"], "type:url text mismatch")
        }

        try run("query parser encrypted no", counter: &count) {
            let parsed = try QueryParser.parse("encrypted:no type:text")
            try expect(parsed.clauses == ["is_encrypted = ?", "kind = ?"], "encrypted=no clauses mismatch")
            try expect(parsed.bindings == [.int(0), .string("text")], "encrypted=no bindings mismatch")
        }

        try run("query parser image alias inline", counter: &count) {
            let parsed = try QueryParser.parse("image:receipt")
            try expect(parsed.clauses == ["kind = ?"], "image alias clause mismatch")
            try expect(parsed.textTerms == ["receipt"], "image alias text mismatch")
        }

        try run("query parser date only", counter: &count) {
            let parsed = try QueryParser.parse("after:2026-04-01")
            try expect(parsed.clauses == ["created_at >= ?"], "after clause mismatch")
            try expect(parsed.bindings == [.double(1_775_001_600)], "after binding mismatch")
        }

        try run("query parser timestamp", counter: &count) {
            let parsed = try QueryParser.parse("after:2026-04-01T15:30:00Z")
            try expect(parsed.bindings == [.double(1_775_057_400)], "timestamp binding mismatch")
        }

        try run("query parser combined filters", counter: &count) {
            let parsed = try QueryParser.parse("app:com.apple.Safari type:text after:2026-04-01 encrypted:yes portal")
            try expect(parsed.clauses == ["source_app = ?", "kind = ?", "created_at >= ?", "is_encrypted = ?"], "combined clauses mismatch")
            try expect(parsed.textTerms == ["portal"], "combined text mismatch")
        }

        try run("query parser invalid type", counter: &count) {
            do {
                _ = try QueryParser.parse("type:file")
                throw VerificationFailure(description: "invalid type did not throw")
            } catch let error as QueryParser.ParseError {
                try expect(error == .invalidType("file"), "invalid type error mismatch")
            }
        }

        try run("query parser invalid date", counter: &count) {
            do {
                _ = try QueryParser.parse("after:not-a-date")
                throw VerificationFailure(description: "invalid date did not throw")
            } catch let error as QueryParser.ParseError {
                try expect(error == .invalidDate("not-a-date"), "invalid date error mismatch")
            }
        }

        try run("query parser invalid encrypted filter", counter: &count) {
            do {
                _ = try QueryParser.parse("encrypted:maybe")
                throw VerificationFailure(description: "invalid encrypted filter did not throw")
            } catch let error as QueryParser.ParseError {
                try expect(error == .invalidEncrypted("maybe"), "invalid encrypted error mismatch")
            }
        }

        try run("url detector matches standalone https", counter: &count) {
            let match = URLDetector.detectStandaloneURL(in: "https://example.com/path?q=1")
            try expect(match?.text == "https://example.com/path?q=1", "https URL mismatch")
        }

        try run("url detector matches mailto", counter: &count) {
            let match = URLDetector.detectStandaloneURL(in: "mailto:ops@example.com")
            try expect(match?.url.scheme == "mailto", "mailto mismatch")
        }

        try run("url detector rejects trailing punctuation", counter: &count) {
            try expect(URLDetector.detectStandaloneURL(in: "https://example.com)") == nil, "trailing punctuation should fail")
        }

        try run("url detector rejects embedded URL", counter: &count) {
            try expect(URLDetector.detectStandaloneURL(in: "see https://example.com for details") == nil, "embedded URL should fail")
        }

        try run("url detector rejects multiple URLs", counter: &count) {
            try expect(URLDetector.detectStandaloneURL(in: "https://one.example https://two.example") == nil, "multiple URLs should fail")
        }

        try run("ocr mock recognizes generated png", counter: &count) {
            let imageData = try makeTextImagePNG(text: "HELLO")
            let recognizer = MockTextRecognizer(expected: imageData, output: "HELLO")
            try expect(recognizer.recognize(imageData) == "HELLO", "mock OCR should return canned text for known PNG")
        }

        try run("config watcher reloads on file write", counter: &count) {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent("config.toml")
            try ConfigFileCodec.encode(.defaultValue).write(to: fileURL, atomically: true, encoding: .utf8)

            let semaphore = DispatchSemaphore(value: 0)
            let watcher = ConfigWatcher(fileURL: fileURL) {
                semaphore.signal()
            }
            watcher.start()
            try "pause_capture = true\nhistory_retention_count = 10\n".write(to: fileURL, atomically: true, encoding: .utf8)
            let result = semaphore.wait(timeout: .now() + 3)
            watcher.stop()
            try expect(result == .success, "config watcher did not fire")
        }

        print("Clip05Verifier: \(count) cases passed")
    }

    private static func run(_ name: String, counter: inout Int, body: () throws -> Void) throws {
        do {
            try body()
            counter += 1
        } catch {
            throw VerificationFailure(description: "\(name): \(error)")
        }
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() {
            throw VerificationFailure(description: message)
        }
    }

    private static func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else {
            throw VerificationFailure(description: message)
        }
        return value
    }

    private static func withStore(_ body: (Store) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try Store(
            configuration: .defaultValue,
            encryptionManager: EncryptionManager(keychain: InMemoryKeychainStore()),
            supportDirectoryURL: directory
        )
        try body(store)
    }

    private static func textDraft(_ text: String) -> ClipDraft {
        ClipDraft(
            createdAt: Date(),
            sourceApp: "com.example.app",
            kind: .text,
            searchablePlaintext: text,
            displayText: text,
            payload: nil,
            payloadBytes: text.lengthOfBytes(using: .utf8),
            imageWidth: nil,
            imageHeight: nil
        )
    }

    private static func imageDraft() throws -> ClipDraft {
        let png = try makeTextImagePNG(text: "SCAN ME")
        return ClipDraft(
            createdAt: Date(),
            sourceApp: "com.example.camera",
            kind: .image,
            searchablePlaintext: "",
            displayText: nil,
            payload: png,
            payloadBytes: png.count,
            imageWidth: 480,
            imageHeight: 160
        )
    }

    private static func makeTextImagePNG(text: String) throws -> Data {
        let width = 900
        let height = 280
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw VerificationFailure(description: "could not create CGContext")
        }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 120, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0, alpha: 1)
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)

        context.textPosition = CGPoint(x: 56, y: 90)
        CTLineDraw(line, context)

        guard let cgImage = context.makeImage(),
              let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw VerificationFailure(description: "could not encode png")
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw VerificationFailure(description: "png finalize failed")
        }

        return mutableData as Data
    }
}

private struct MockTextRecognizer {
    let expected: Data
    let output: String

    func recognize(_ data: Data) -> String? {
        data == expected ? output : nil
    }
}

do {
    try Clip05Verifier.main()
} catch {
    fputs("Clip05Verifier failed: \(error)\n", stderr)
    exit(1)
}
