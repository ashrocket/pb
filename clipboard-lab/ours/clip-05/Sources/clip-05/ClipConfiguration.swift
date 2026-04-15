import AppKit
import Carbon
import Darwin
import Foundation

enum HotkeyModifierPreset: String, CaseIterable, Equatable {
    case commandShift = "command_shift"
    case commandOption = "command_option"
    case commandControl = "command_control"
    case optionControl = "option_control"
    case commandShiftOption = "command_shift_option"

    var carbonFlags: UInt32 {
        switch self {
        case .commandShift:
            return UInt32(cmdKey | shiftKey)
        case .commandOption:
            return UInt32(cmdKey | optionKey)
        case .commandControl:
            return UInt32(cmdKey | controlKey)
        case .optionControl:
            return UInt32(optionKey | controlKey)
        case .commandShiftOption:
            return UInt32(cmdKey | shiftKey | optionKey)
        }
    }

    var displayName: String {
        switch self {
        case .commandShift:
            return "Command + Shift + V"
        case .commandOption:
            return "Command + Option + V"
        case .commandControl:
            return "Command + Control + V"
        case .optionControl:
            return "Option + Control + V"
        case .commandShiftOption:
            return "Command + Shift + Option + V"
        }
    }
}

struct ClipConfiguration: Equatable {
    var autoStartAtLogin: Bool
    var excludedBundleIDs: [String]
    var historyRetentionCount: Int
    var hotkeyModifiers: HotkeyModifierPreset
    var maxBytesPerClip: Int
    var pauseCapture: Bool
    var pollingIntervalSeconds: Double

    static let defaultValue = ClipConfiguration(
        autoStartAtLogin: false,
        excludedBundleIDs: [],
        historyRetentionCount: 250,
        hotkeyModifiers: .commandShift,
        maxBytesPerClip: 1_048_576,
        pauseCapture: false,
        pollingIntervalSeconds: 0.6
    )
}

enum ConfigFileCodec {
    static func decode(_ raw: String) -> ClipConfiguration {
        var configuration = ClipConfiguration.defaultValue

        if let autoStartAtLogin = matchBoolean(for: "auto_start_at_login", in: raw) {
            configuration.autoStartAtLogin = autoStartAtLogin
        }

        if let pauseCapture = matchBoolean(for: "pause_capture", in: raw) {
            configuration.pauseCapture = pauseCapture
        }

        if let historyRetentionCount = matchInteger(for: "history_retention_count", in: raw), historyRetentionCount > 0 {
            configuration.historyRetentionCount = historyRetentionCount
        }

        if let maxBytes = matchInteger(for: "max_bytes_per_clip", in: raw), maxBytes > 0 {
            configuration.maxBytesPerClip = maxBytes
        }

        if let pollingInterval = matchDouble(for: "polling_interval_seconds", in: raw), pollingInterval >= 0.1 {
            configuration.pollingIntervalSeconds = pollingInterval
        }

        if let hotkeyValue = matchString(for: "hotkey_modifiers", in: raw),
           let hotkeyModifiers = HotkeyModifierPreset(rawValue: hotkeyValue) {
            configuration.hotkeyModifiers = hotkeyModifiers
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
        auto_start_at_login = \(configuration.autoStartAtLogin ? "true" : "false")
        pause_capture = \(configuration.pauseCapture ? "true" : "false")
        history_retention_count = \(configuration.historyRetentionCount)
        max_bytes_per_clip = \(configuration.maxBytesPerClip)
        polling_interval_seconds = \(String(format: "%.2f", configuration.pollingIntervalSeconds))
        hotkey_modifiers = "\(configuration.hotkeyModifiers.rawValue)"
        \(arrayBlock)
        """
    }

    private static func matchBoolean(for key: String, in text: String) -> Bool? {
        guard let value = matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*(true|false)\\s*$", in: text, capture: 1) else {
            return nil
        }
        return value == "true"
    }

    private static func matchDouble(for key: String, in text: String) -> Double? {
        guard let value = matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*(\\d+(?:\\.\\d+)?)\\s*$", in: text, capture: 1) else {
            return nil
        }
        return Double(value)
    }

    private static func matchInteger(for key: String, in text: String) -> Int? {
        guard let value = matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*(\\d+)\\s*$", in: text, capture: 1) else {
            return nil
        }
        return Int(value)
    }

    private static func matchString(for key: String, in text: String) -> String? {
        matchPattern("(?m)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*\"([^\"]+)\"\\s*$", in: text, capture: 1)
    }

    private static func matchStringArray(for key: String, in text: String) -> [String]? {
        guard let body = matchPattern("(?ms)^\\s*\(NSRegularExpression.escapedPattern(for: key))\\s*=\\s*\\[(.*?)\\]", in: text, capture: 1) else {
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

final class ConfigWatcher {
    private let fileURL: URL
    private let queue: DispatchQueue
    private let callback: () -> Void

    private var descriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?

    init(fileURL: URL, callback: @escaping () -> Void) {
        self.fileURL = fileURL
        self.callback = callback
        queue = DispatchQueue(label: "local.clip05.configwatch")
    }

    deinit {
        stop()
    }

    func start() {
        guard source == nil else {
            return
        }

        let watchedPath = fileURL.deletingLastPathComponent().path
        descriptor = open(watchedPath, O_EVTONLY)
        guard descriptor >= 0 else {
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: queue
        )

        source.setEventHandler { [callback] in
            callback()
        }

        source.setCancelHandler { [descriptor] in
            if descriptor >= 0 {
                close(descriptor)
            }
        }

        self.source = source
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        descriptor = -1
    }
}

@MainActor
final class ConfigController {
    private let fileManager: FileManager
    private let supportDirectoryURL: URL
    private var watcher: ConfigWatcher?

    private(set) var currentConfiguration: ClipConfiguration = .defaultValue
    let configURL: URL

    var onChange: ((ClipConfiguration) -> Void)?

    init(fileManager: FileManager = .default, supportDirectoryURL: URL? = nil) throws {
        self.fileManager = fileManager

        if let supportDirectoryURL {
            self.supportDirectoryURL = supportDirectoryURL
        } else {
            guard let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw StoreError.pathResolutionFailed
            }
            self.supportDirectoryURL = supportRoot.appendingPathComponent("clip-05", isDirectory: true)
        }

        try fileManager.createDirectory(at: self.supportDirectoryURL, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: self.supportDirectoryURL.path)

        configURL = self.supportDirectoryURL.appendingPathComponent("config.toml", isDirectory: false)

        try ensureDefaultConfigExists()
        currentConfiguration = try loadConfiguration()
    }

    func startMonitoring() {
        guard watcher == nil else {
            return
        }

        watcher = ConfigWatcher(fileURL: configURL) { [weak self] in
            DispatchQueue.main.async {
                self?.reloadFromDisk()
            }
        }
        watcher?.start()
    }

    func stopMonitoring() {
        watcher?.stop()
        watcher = nil
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
}
