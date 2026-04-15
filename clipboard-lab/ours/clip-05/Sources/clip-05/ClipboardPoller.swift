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

    private var timer: Timer?
    private var observedChangeCount: Int
    private var configuration: ClipConfiguration

    var ocrService: OCRService?
    var onNewRecord: ((ClipRecord) -> Void)?
    var onRecordUpdated: ((String) -> Void)?

    init(
        pasteboard: NSPasteboard = .general,
        store: Store,
        configuration: ClipConfiguration
    ) {
        self.pasteboard = pasteboard
        self.store = store
        self.configuration = configuration
        observedChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else {
            return
        }
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func applyConfiguration(_ configuration: ClipConfiguration) {
        let oldInterval = normalizedPollingInterval()
        self.configuration = configuration
        if configuration.pauseCapture {
            observedChangeCount = pasteboard.changeCount
        }

        if oldInterval != normalizedPollingInterval() {
            restartTimer()
        }
    }

    func ignoreCurrentPasteboardState() {
        observedChangeCount = pasteboard.changeCount
    }

    private func restartTimer() {
        stop()
        scheduleTimer()
    }

    private func scheduleTimer() {
        let interval = normalizedPollingInterval()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        timer?.tolerance = interval * 0.25
    }

    private func normalizedPollingInterval() -> TimeInterval {
        max(0.1, configuration.pollingIntervalSeconds)
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
                scheduleOCRIfNeeded(for: record)
            }
        } catch {
            // Clipboard contents must not be logged.
        }
    }

    private func scheduleOCRIfNeeded(for record: ClipRecord) {
        guard record.kind == .image,
              let payload = record.payload,
              let ocrService else {
            return
        }

        ocrService.recognizeText(in: payload) { [weak self] recognizedText in
            guard let self, let recognizedText else {
                return
            }

            DispatchQueue.global(qos: .utility).async { [store] in
                do {
                    try store.updateRecognizedText(recognizedText, forClipID: record.id)
                    DispatchQueue.main.async {
                        self.onRecordUpdated?(record.id)
                    }
                } catch {
                    // OCR failures stay local and silent.
                }
            }
        }
    }

    private func makeDraft(from item: NSPasteboardItem, sourceApp: String?) -> ClipDraft? {
        let capturedAt = Date()

        if let text = item.string(forType: .string) {
            let normalized = normalize(text)
            guard !normalized.isEmpty else {
                return nil
            }

            if let detectedURL = URLDetector.detectStandaloneURL(in: normalized) {
                return ClipDraft(
                    createdAt: capturedAt,
                    sourceApp: sourceApp,
                    kind: .url,
                    searchablePlaintext: detectedURL.url.absoluteString,
                    displayText: detectedURL.text,
                    payload: nil,
                    payloadBytes: normalized.lengthOfBytes(using: .utf8),
                    imageWidth: nil,
                    imageHeight: nil
                )
            }

            return ClipDraft(
                createdAt: capturedAt,
                sourceApp: sourceApp,
                kind: .text,
                searchablePlaintext: normalized,
                displayText: normalized,
                payload: nil,
                payloadBytes: normalized.lengthOfBytes(using: .utf8),
                imageWidth: nil,
                imageHeight: nil
            )
        }

        guard let image = NSImage(pasteboard: pasteboard),
              let encoded = encodePNG(image) else {
            return nil
        }

        return ClipDraft(
            createdAt: capturedAt,
            sourceApp: sourceApp,
            kind: .image,
            searchablePlaintext: "",
            displayText: nil,
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
