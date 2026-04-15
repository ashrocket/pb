import AppKit
import Foundation

@MainActor
final class ClipboardPoller {
    private let excludedTypes: Set<NSPasteboard.PasteboardType> = [
        NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
        NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
    ]

    private let pasteboard: NSPasteboard
    private let store: Store
    private let pollingInterval: TimeInterval

    private var timer: Timer?
    private var observedChangeCount: Int
    private var configuration: ClipConfiguration

    var onNewRecord: ((ClipRecord) -> Void)?

    init(
        pasteboard: NSPasteboard = .general,
        store: Store,
        configuration: ClipConfiguration,
        pollingInterval: TimeInterval = 0.75
    ) {
        self.pasteboard = pasteboard
        self.store = store
        self.configuration = configuration
        self.pollingInterval = pollingInterval
        observedChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        timer?.tolerance = pollingInterval * 0.25
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func applyConfiguration(_ configuration: ClipConfiguration) {
        self.configuration = configuration
        if configuration.pauseCapture {
            observedChangeCount = pasteboard.changeCount
        }
    }

    func ignoreCurrentPasteboardState() {
        observedChangeCount = pasteboard.changeCount
    }

    private func poll() {
        guard pasteboard.changeCount != observedChangeCount else {
            return
        }
        observedChangeCount = pasteboard.changeCount

        guard !configuration.pauseCapture else {
            return
        }

        guard let item = pasteboard.pasteboardItems?.first else {
            return
        }

        let itemTypes = Set(item.types)
        guard excludedTypes.isDisjoint(with: itemTypes) else {
            return
        }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if let sourceApp, configuration.excludedBundleIDs.contains(sourceApp) {
            return
        }

        guard let draft = makeDraft(from: item, sourceApp: sourceApp) else {
            return
        }

        guard draft.payloadBytes <= configuration.maxBytesPerClip else {
            return
        }

        do {
            if let record = try store.save(draft) {
                onNewRecord?(record)
            }
        } catch {
            // Clipboard contents must not be logged.
        }
    }

    private func makeDraft(from item: NSPasteboardItem, sourceApp: String?) -> ClipDraft? {
        let capturedAt = Date()

        if let text = item.string(forType: .string) {
            let normalized = normalize(text)
            guard !normalized.isEmpty else {
                return nil
            }

            let byteCount = normalized.lengthOfBytes(using: .utf8)
            let searchText = [sourceApp, normalized]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            return ClipDraft(
                createdAt: capturedAt,
                sourceApp: sourceApp,
                kind: .text,
                searchableText: searchText,
                textValue: normalized,
                payload: nil,
                payloadBytes: byteCount,
                imageWidth: nil,
                imageHeight: nil
            )
        }

        guard let image = NSImage(pasteboard: pasteboard),
              let encoded = encodePNG(image) else {
            return nil
        }

        let dimensions = "\(encoded.width)x\(encoded.height)"
        let byteLabel = ByteCountFormatter.string(fromByteCount: Int64(encoded.data.count), countStyle: .file)
            .replacingOccurrences(of: " ", with: "")
        let searchText = [sourceApp, "image", "png", dimensions, "\(encoded.width)", "\(encoded.height)", byteLabel]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return ClipDraft(
            createdAt: capturedAt,
            sourceApp: sourceApp,
            kind: .image,
            searchableText: searchText,
            textValue: nil,
            payload: encoded.data,
            payloadBytes: encoded.data.count,
            imageWidth: encoded.width,
            imageHeight: encoded.height
        )
    }

    private func encodePNG(_ image: NSImage) -> (data: Data, width: Int, height: Int)? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let width = bitmap.pixelsWide > 0 ? bitmap.pixelsWide : Int(image.size.width)
        let height = bitmap.pixelsHigh > 0 ? bitmap.pixelsHigh : Int(image.size.height)
        return (pngData, width, height)
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
