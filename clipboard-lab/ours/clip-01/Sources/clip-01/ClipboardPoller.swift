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

    var onNewRecord: ((ClipRecord) -> Void)?

    init(
        pasteboard: NSPasteboard = .general,
        store: Store,
        pollingInterval: TimeInterval = 0.75
    ) {
        self.pasteboard = pasteboard
        self.store = store
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

    private func poll() {
        guard pasteboard.changeCount != observedChangeCount else {
            return
        }
        observedChangeCount = pasteboard.changeCount

        guard let item = pasteboard.pasteboardItems?.first else {
            return
        }

        let itemTypes = Set(item.types)
        guard excludedTypes.isDisjoint(with: itemTypes) else {
            return
        }

        guard let draft = makeDraft(from: item) else {
            return
        }

        do {
            if let record = try store.save(draft) {
                onNewRecord?(record)
            }
        } catch {
            // Intentionally silent: clipboard contents must not be logged.
        }
    }

    private func makeDraft(from item: NSPasteboardItem) -> ClipDraft? {
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let capturedAt = Date()

        if let text = item.string(forType: .string) {
            let normalized = normalize(text)
            guard !normalized.isEmpty else {
                return nil
            }
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
                payload: nil
            )
        }

        if let image = NSImage(pasteboard: pasteboard), let imageData = image.tiffRepresentation {
            let searchText = [sourceApp, "image"]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return ClipDraft(
                createdAt: capturedAt,
                sourceApp: sourceApp,
                kind: .image,
                searchableText: searchText,
                textValue: nil,
                payload: imageData
            )
        }

        return nil
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
