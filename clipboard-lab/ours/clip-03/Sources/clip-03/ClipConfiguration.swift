import AppKit
import CoreServices
import Foundation

struct ClipConfiguration: Equatable {
    var excludedBundleIDs: [String]
    var maxBytesPerClip: Int
    var pauseCapture: Bool

    static let defaultValue = ClipConfiguration(
        excludedBundleIDs: [],
        maxBytesPerClip: 1_048_576,
        pauseCapture: false
    )
}

enum ConfigFileCodec {
    static func decode(_ raw: String) -> ClipConfiguration {
        var configuration = ClipConfiguration.defaultValue

        if let pauseCapture = matchBoolean(for: "pause_capture", in: raw) {
            configuration.pauseCapture = pauseCapture
        }

        if let maxBytes = matchInteger(for: "max_bytes_per_clip", in: raw), maxBytes > 0 {
            configuration.maxBytesPerClip = maxBytes
        }

        if let bundleIDs = matchStringArray(for: "excluded_bundle_ids", in: raw) {
            configuration.excludedBundleIDs = bundleIDs.sorted()
        }

        return configuration
    }

    static func encode(_ configuration: ClipConfiguration) -> String {
        let bundleLines = configuration.excludedBundleIDs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
            .map { "    \"\($0)\"," }
            .joined(separator: "\n")

        let arrayBlock: String
        if bundleLines.isEmpty {
            arrayBlock = """
            excluded_bundle_ids = [
            ]
            """
        } else {
            arrayBlock = """
            excluded_bundle_ids = [
            \(bundleLines)
            ]
            """
        }

        return """
        pause_capture = \(configuration.pauseCapture ? "true" : "false")
        max_bytes_per_clip = \(configuration.maxBytesPerClip)
        \(arrayBlock)
        """
    }

    private static func matchBoolean(for key: String, in text: String) -> Bool? {
        guard let value = matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*(true|false)\\s*$", in: text, capture: 1) else {
            return nil
        }
        return value == "true"
    }

    private static func matchInteger(for key: String, in text: String) -> Int? {
        guard let value = matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*(\\d+)\\s*$", in: text, capture: 1) else {
            return nil
        }
        return Int(value)
    }

    private static func matchStringArray(for key: String, in text: String) -> [String]? {
        guard let body = matchPattern("(?s)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*\\[(.*?)\\]", in: text, capture: 1) else {
            return nil
        }

        let regex = try? NSRegularExpression(pattern: #""([^"]+)""#)
        let range = NSRange(body.startIndex..<body.endIndex, in: body)
        return (regex?.matches(in: body, range: range) ?? []).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: body) else {
                return nil
            }
            return String(body[capture])
        }
    }

    private static func matchPattern(_ pattern: String, in text: String, capture: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let captureRange = Range(match.range(at: capture), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}

@MainActor
final class ConfigController {
    private let fileManager: FileManager
    private let supportDirectoryURL: URL
    private let streamQueue = DispatchQueue(label: "local.clip03.config")

    private var stream: FSEventStreamRef?

    private(set) var currentConfiguration: ClipConfiguration = .defaultValue
    let configURL: URL

    var onChange: ((ClipConfiguration) -> Void)?

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        guard let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StoreError.pathResolutionFailed
        }

        supportDirectoryURL = supportRoot.appendingPathComponent("clip-03", isDirectory: true)
        try fileManager.createDirectory(at: supportDirectoryURL, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: supportDirectoryURL.path)

        configURL = supportDirectoryURL.appendingPathComponent("config.toml", isDirectory: false)

        try ensureDefaultConfigExists()
        currentConfiguration = try loadConfiguration()
    }

    func startMonitoring() {
        guard stream == nil else {
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagNoDefer
        )

        guard let stream = FSEventStreamCreate(
            nil,
            configStreamCallback,
            &context,
            [configURL.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.25,
            flags
        ) else {
            return
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, streamQueue)
        FSEventStreamStart(stream)
    }

    func stopMonitoring() {
        guard let stream else {
            return
        }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    func reloadFromDisk() {
        guard let configuration = try? loadConfiguration(),
              configuration != currentConfiguration else {
            return
        }

        currentConfiguration = configuration
        onChange?(configuration)
    }

    func save(_ configuration: ClipConfiguration) throws {
        let serialized = ConfigFileCodec.encode(configuration)
        try serialized.write(to: configURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)

        guard configuration != currentConfiguration else {
            return
        }

        currentConfiguration = configuration
        onChange?(configuration)
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }

    private func ensureDefaultConfigExists() throws {
        guard !fileManager.fileExists(atPath: configURL.path) else {
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)
            return
        }

        try ConfigFileCodec.encode(.defaultValue).write(to: configURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)
    }

    private func loadConfiguration() throws -> ClipConfiguration {
        let raw = try String(contentsOf: configURL, encoding: .utf8)
        return ConfigFileCodec.decode(raw)
    }

    fileprivate func isRelevantEventPath(_ path: String) -> Bool {
        let eventURL = URL(fileURLWithPath: path).standardizedFileURL
        if eventURL.path == configURL.standardizedFileURL.path {
            return true
        }
        return eventURL.lastPathComponent == configURL.lastPathComponent
    }
}

private func configStreamCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let clientCallBackInfo else {
        return
    }

    let controller = Unmanaged<ConfigController>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []

    Task { @MainActor in
        guard paths.contains(where: { controller.isRelevantEventPath($0) }) else {
            return
        }
        controller.reloadFromDisk()
    }
}
