import AppKit
import Foundation

@MainActor
final class HistoryWindowController: NSWindowController, NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private enum Metrics {
        static let pageSize = 20
    }

    private let store: Store
    private let onChooseRecord: (ClipRecord) -> Void
    private let fetchQueue = DispatchQueue(label: "local.clip05.fetch", qos: .userInitiated)

    private let searchField = NSSearchField(frame: .zero)
    private let tableView = HoverTableView(frame: .zero)
    private let scrollView = NSScrollView(frame: .zero)
    private let emptyLabel = NSTextField(labelWithString: "No clipboard history yet")
    private let hintLabel = NSTextField(labelWithString: "Query: words  •  type:text|image|url  •  app:<bundleid>  •  after:<iso-date>  •  encrypted:yes|no")
    private let captureStatusLabel = NSTextField(labelWithString: "")
    private let queryStatusLabel = NSTextField(labelWithString: "")
    private let previewPane = PreviewPaneView(frame: .zero)

    private var records: [ClipRecord] = []
    private var hasMore = false
    private var isLoading = false
    private var loadGeneration = 0
    private var keyMonitor: Any?
    private var searchDebounceTimer: Timer?

    init(store: Store, onChooseRecord: @escaping (ClipRecord) -> Void) {
        self.store = store
        self.onChooseRecord = onChooseRecord

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Clipboard History"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.minSize = NSSize(width: 840, height: 460)
        panel.acceptsMouseMovedEvents = true

        super.init(window: panel)
        buildUI()
        installKeyboardMonitor()
        reloadData(reset: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func toggle() {
        guard let window else {
            return
        }

        if window.isVisible {
            window.orderOut(nil)
            return
        }

        reloadData(reset: true)
        positionWindow()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        searchField.becomeFirstResponder()
    }

    func reloadData(reset: Bool = true) {
        loadPage(reset: reset)
    }

    func setCapturePaused(_ paused: Bool) {
        captureStatusLabel.stringValue = paused ? "Capture paused in settings" : ""
        captureStatusLabel.isHidden = !paused
    }

    func refreshRecord(id: String) {
        guard let row = records.firstIndex(where: { $0.id == id }) else {
            return
        }

        loadGeneration += 1
        let generation = loadGeneration
        let offset = row
        let query = currentSearch()

        fetchQueue.async { [store] in
            let result = store.fetchPage(search: query, offset: offset, limit: 1)
            DispatchQueue.main.async {
                guard generation == self.loadGeneration, let refreshed = result.records.first else {
                    return
                }
                self.records[row] = refreshed
                self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
                if self.tableView.selectedRow == row {
                    self.previewPane.configure(with: refreshed)
                }
            }
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadData(reset: true)
            }
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        records.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        72
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        HighlightRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipCell")
        let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? ClipCellView) ?? ClipCellView(frame: .zero)
        cell.identifier = identifier
        cell.configure(with: records[row], index: row)
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0, tableView.selectedRow < records.count else {
            previewPane.configure(with: nil)
            return
        }

        previewPane.configure(with: records[tableView.selectedRow])
    }

    @objc func activateSelection() {
        guard tableView.selectedRow >= 0, tableView.selectedRow < records.count else {
            return
        }
        let record = records[tableView.selectedRow]
        onChooseRecord(record)
        window?.orderOut(nil)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else {
            return
        }

        let background = NSVisualEffectView(frame: contentView.bounds)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.blendingMode = .behindWindow
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 18
        contentView.addSubview(background)

        searchField.placeholderString = "Search encrypted history"
        searchField.delegate = self
        searchField.focusRingType = .none
        searchField.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        captureStatusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        captureStatusLabel.textColor = .systemOrange
        captureStatusLabel.isHidden = true
        captureStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        queryStatusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        queryStatusLabel.textColor = .systemRed
        queryStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("clip"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowSizeStyle = .default
        tableView.intercellSpacing = NSSize(width: 0, height: 8)
        tableView.allowsEmptySelection = false
        tableView.focusRingType = .none
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.backgroundColor = .clear
        tableView.doubleAction = #selector(activateSelection)
        tableView.target = self
        tableView.onHoveredRow = { [weak self] row in
            guard let self, row >= 0, row < self.records.count else {
                return
            }
            self.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        tableView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        let splitView = NSSplitView(frame: .zero)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false

        let listContainer = NSVisualEffectView(frame: .zero)
        listContainer.material = .sidebar
        listContainer.blendingMode = .withinWindow
        listContainer.state = .active
        listContainer.translatesAutoresizingMaskIntoConstraints = false

        listContainer.addSubview(scrollView)
        listContainer.addSubview(emptyLabel)

        splitView.addArrangedSubview(listContainer)
        splitView.addArrangedSubview(previewPane)
        splitView.setPosition(460, ofDividerAt: 0)

        background.addSubview(searchField)
        background.addSubview(hintLabel)
        background.addSubview(captureStatusLabel)
        background.addSubview(queryStatusLabel)
        background.addSubview(splitView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScrollBoundsChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: contentView.topAnchor),
            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            searchField.topAnchor.constraint(equalTo: background.topAnchor, constant: 18),
            searchField.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 18),
            searchField.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -18),

            hintLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),

            captureStatusLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 8),
            captureStatusLabel.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),

            queryStatusLabel.centerYAnchor.constraint(equalTo: captureStatusLabel.centerYAnchor),
            queryStatusLabel.trailingAnchor.constraint(equalTo: searchField.trailingAnchor),
            queryStatusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: captureStatusLabel.trailingAnchor, constant: 12),

            splitView.topAnchor.constraint(equalTo: captureStatusLabel.bottomAnchor, constant: 14),
            splitView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 18),
            splitView.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -18),
            splitView.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -18),

            scrollView.topAnchor.constraint(equalTo: listContainer.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: listContainer.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: listContainer.trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: listContainer.bottomAnchor, constant: -12),

            emptyLabel.centerXAnchor.constraint(equalTo: listContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: listContainer.centerYAnchor)
        ])
    }

    private func installKeyboardMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }
            return self.handleKeyEvent(event) ? nil : event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let window, window.isVisible, window.isKeyWindow else {
            return false
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == [.command], let quickPickIndex = quickPickIndex(for: event) {
            chooseRow(at: quickPickIndex)
            return true
        }

        switch event.keyCode {
        case 125:
            moveSelection(by: 1)
            return true
        case 126:
            moveSelection(by: -1)
            return true
        case 36, 76:
            activateSelection()
            return true
        case 53:
            window.orderOut(nil)
            return true
        default:
            return false
        }
    }

    private func quickPickIndex(for event: NSEvent) -> Int? {
        guard let characters = event.charactersIgnoringModifiers, characters.count == 1,
              let scalar = characters.unicodeScalars.first else {
            return nil
        }

        switch scalar.value {
        case 49...57:
            return Int(scalar.value - 49)
        case 48:
            return 9
        default:
            return nil
        }
    }

    private func moveSelection(by delta: Int) {
        guard !records.isEmpty else {
            return
        }

        let currentRow = max(tableView.selectedRow, 0)
        let targetRow = min(max(currentRow + delta, 0), records.count - 1)
        tableView.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)
        tableView.scrollRowToVisible(targetRow)
        maybeLoadMoreIfNeeded(visibleRow: targetRow)
    }

    private func chooseRow(at index: Int) {
        guard index >= 0, index < records.count else {
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        activateSelection()
    }

    private func loadPage(reset: Bool) {
        guard !isLoading else {
            return
        }

        if reset {
            records = []
            tableView.reloadData()
            previewPane.configure(with: nil)
        }

        isLoading = true
        queryStatusLabel.stringValue = "Loading…"
        queryStatusLabel.textColor = .secondaryLabelColor

        loadGeneration += 1
        let generation = loadGeneration
        let offset = reset ? 0 : records.count
        let query = currentSearch()

        fetchQueue.async { [store] in
            let result = store.fetchPage(search: query, offset: offset, limit: Metrics.pageSize)
            DispatchQueue.main.async {
                guard generation == self.loadGeneration else {
                    return
                }

                self.isLoading = false
                self.hasMore = result.hasMore
                self.queryStatusLabel.stringValue = result.error ?? ""
                self.queryStatusLabel.textColor = result.error == nil ? .secondaryLabelColor : .systemRed

                if result.error == nil {
                    self.queryStatusLabel.stringValue = self.hasMore ? "Loaded \(offset + result.records.count)+" : ""
                }

                if reset {
                    self.records = result.records
                } else {
                    self.records.append(contentsOf: result.records.filter { candidate in
                        !self.records.contains(where: { $0.id == candidate.id })
                    })
                }

                self.tableView.reloadData()
                self.emptyLabel.isHidden = !self.records.isEmpty
                self.restoreSelection(reset: reset)
            }
        }
    }

    @objc private func handleScrollBoundsChange() {
        let visibleRows = tableView.rows(in: scrollView.contentView.bounds)
        let visibleRow = visibleRows.length > 0 ? (visibleRows.location + visibleRows.length - 1) : 0
        maybeLoadMoreIfNeeded(visibleRow: visibleRow)
    }

    private func maybeLoadMoreIfNeeded(visibleRow: Int) {
        guard hasMore, !isLoading, visibleRow >= records.count - 5 else {
            return
        }
        loadPage(reset: false)
    }

    private func restoreSelection(reset: Bool) {
        guard !records.isEmpty else {
            previewPane.configure(with: nil)
            return
        }

        let target = reset ? 0 : max(min(tableView.selectedRow, records.count - 1), 0)
        tableView.selectRowIndexes(IndexSet(integer: target), byExtendingSelection: false)
        tableView.scrollRowToVisible(target)
        previewPane.configure(with: records[target])
    }

    private func currentSearch() -> String? {
        let trimmed = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func positionWindow() {
        guard let screenFrame = NSScreen.main?.visibleFrame,
              let window else {
            return
        }

        let size = window.frame.size
        let origin = NSPoint(
            x: screenFrame.midX - (size.width / 2),
            y: screenFrame.midY - (size.height / 2)
        )
        window.setFrameOrigin(origin)
    }
}

private final class HoverTableView: NSTableView {
    var onHoveredRow: ((Int) -> Void)?
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        if row >= 0 {
            onHoveredRow?(row)
        }
        super.mouseMoved(with: event)
    }
}

private final class HighlightRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        let selectionRect = bounds.insetBy(dx: 4, dy: 2)
        let path = NSBezierPath(roundedRect: selectionRect, xRadius: 12, yRadius: 12)
        let color = window?.isKeyWindow == true
            ? NSColor.controlAccentColor.withAlphaComponent(0.24)
            : NSColor.selectedControlColor.withAlphaComponent(0.18)
        color.setFill()
        path.fill()
    }
}

private final class ClipCellView: NSTableCellView {
    private let indexLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let thumbnailView = RoundedImageView(frame: .zero)
    private var representedID: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with record: ClipRecord, index: Int) {
        representedID = record.id
        indexLabel.stringValue = index < 10 ? "\(index == 9 ? 0 : index + 1)." : ""
        titleLabel.stringValue = record.titleText
        detailLabel.stringValue = record.detailText
        thumbnailView.image = nil
        thumbnailView.isHidden = record.kind != .image

        guard record.kind == .image, let payload = record.payload else {
            return
        }

        ThumbnailBroker.shared.loadThumbnail(id: record.id, data: payload, maxPixelSize: 96) { [weak self] image in
            guard let self, self.representedID == record.id else {
                return
            }
            self.thumbnailView.image = image
        }
    }

    private func buildUI() {
        wantsLayer = true

        indexLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        indexLabel.textColor = .secondaryLabelColor
        indexLabel.alignment = .right
        indexLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = NSFont.systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.imageScaling = .scaleAxesIndependently

        addSubview(indexLabel)
        addSubview(thumbnailView)
        addSubview(titleLabel)
        addSubview(detailLabel)

        NSLayoutConstraint.activate([
            indexLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            indexLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            indexLabel.widthAnchor.constraint(equalToConstant: 24),

            thumbnailView.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 8),
            thumbnailView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 48),
            thumbnailView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
    }
}

private final class RoundedImageView: NSImageView {
    override func layout() {
        super.layout()
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.6).cgColor
    }
}

private final class PreviewPaneView: NSVisualEffectView {
    private let titleLabel = NSTextField(labelWithString: "Select a clip")
    private let detailLabel = NSTextField(labelWithString: "Use the arrow keys, search field, or hover to inspect a clip before pasting.")
    private let imageView = RoundedImageView(frame: .zero)
    private let bodyScrollView = NSScrollView(frame: .zero)
    private let bodyTextView = NSTextView(frame: .zero)
    private let recognizedTextLabel = NSTextField(labelWithString: "")
    private var representedID: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .underWindowBackground
        blendingMode = .withinWindow
        state = .active
        translatesAutoresizingMaskIntoConstraints = false
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with record: ClipRecord?) {
        representedID = record?.id

        guard let record else {
            titleLabel.stringValue = "Select a clip"
            detailLabel.stringValue = "Use the arrow keys, search field, or hover to inspect a clip before pasting."
            bodyTextView.string = ""
            recognizedTextLabel.stringValue = ""
            imageView.image = nil
            imageView.isHidden = false
            return
        }

        titleLabel.stringValue = record.titleText
        detailLabel.stringValue = record.detailText
        recognizedTextLabel.stringValue = record.recognizedText.map { "OCR\n\($0)" } ?? ""

        switch record.kind {
        case .text, .url:
            imageView.image = nil
            bodyTextView.string = record.displayText ?? ""
        case .image:
            bodyTextView.string = record.recognizedText ?? "No recognized text yet."
            imageView.image = nil
            if let payload = record.payload {
                ThumbnailBroker.shared.loadPreviewImage(id: record.id, data: payload) { [weak self] image in
                    guard let self, self.representedID == record.id else {
                        return
                    }
                    self.imageView.image = image
                }
            }
        }
    }

    private func buildUI() {
        wantsLayer = true
        layer?.cornerRadius = 18

        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = NSFont.systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown

        bodyTextView.isEditable = false
        bodyTextView.isSelectable = true
        bodyTextView.isRichText = false
        bodyTextView.drawsBackground = false
        bodyTextView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        bodyTextView.textColor = .labelColor

        bodyScrollView.drawsBackground = false
        bodyScrollView.borderType = .noBorder
        bodyScrollView.hasVerticalScroller = true
        bodyScrollView.documentView = bodyTextView
        bodyScrollView.translatesAutoresizingMaskIntoConstraints = false

        recognizedTextLabel.font = NSFont.systemFont(ofSize: 12)
        recognizedTextLabel.textColor = .secondaryLabelColor
        recognizedTextLabel.lineBreakMode = .byWordWrapping
        recognizedTextLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(imageView)
        addSubview(bodyScrollView)
        addSubview(recognizedTextLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 240),

            bodyScrollView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            bodyScrollView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            bodyScrollView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            bodyScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            recognizedTextLabel.topAnchor.constraint(equalTo: bodyScrollView.bottomAnchor, constant: 12),
            recognizedTextLabel.leadingAnchor.constraint(equalTo: bodyScrollView.leadingAnchor),
            recognizedTextLabel.trailingAnchor.constraint(equalTo: bodyScrollView.trailingAnchor),
            recognizedTextLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
}

private final class ThumbnailBroker: @unchecked Sendable {
    static let shared = ThumbnailBroker()

    private let queue = DispatchQueue(label: "local.clip05.thumbs", qos: .utility)
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let previewCache = NSCache<NSString, NSImage>()

    func loadThumbnail(id: String, data: Data, maxPixelSize: CGFloat, completion: @MainActor @escaping (NSImage?) -> Void) {
        let key = "\(id)-thumb-\(Int(maxPixelSize))"
        if let cached = thumbnailCache.object(forKey: key as NSString) {
            Task { @MainActor in
                completion(cached)
            }
            return
        }

        queue.async {
            let image = ImageDecoding.decodeThumbnail(from: data, maxPixelSize: maxPixelSize)
            if let image {
                self.thumbnailCache.setObject(image, forKey: key as NSString)
            }
            Task { @MainActor in
                completion(image)
            }
        }
    }

    func loadPreviewImage(id: String, data: Data, completion: @MainActor @escaping (NSImage?) -> Void) {
        let key = "\(id)-preview"
        if let cached = previewCache.object(forKey: key as NSString) {
            Task { @MainActor in
                completion(cached)
            }
            return
        }

        queue.async {
            let image = ImageDecoding.decodeFullImage(from: data)
            if let image {
                self.previewCache.setObject(image, forKey: key as NSString)
            }
            Task { @MainActor in
                completion(image)
            }
        }
    }
}
