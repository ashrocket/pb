import AppKit
import Foundation

@MainActor
final class HistoryWindowController: NSWindowController, NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let store: Store
    private let onChooseRecord: (ClipRecord) -> Void

    private let searchField = NSSearchField(frame: .zero)
    private let tableView = NSTableView(frame: .zero)
    private let scrollView = NSScrollView(frame: .zero)
    private let emptyLabel = NSTextField(labelWithString: "No clipboard history yet")
    private let hintLabel = NSTextField(labelWithString: "Query: words  •  type:text|image|url  •  app:<bundleid>  •  after:<iso-date>  •  encrypted:yes|no")
    private let captureStatusLabel = NSTextField(labelWithString: "")
    private let queryStatusLabel = NSTextField(labelWithString: "")

    private var records: [ClipRecord] = []
    private var keyMonitor: Any?

    init(store: Store, onChooseRecord: @escaping (ClipRecord) -> Void) {
        self.store = store
        self.onChooseRecord = onChooseRecord

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Clipboard History"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.minSize = NSSize(width: 520, height: 320)

        super.init(window: panel)
        buildUI()
        installKeyboardMonitor()
        reloadData()
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

        reloadData()
        positionWindow()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        searchField.becomeFirstResponder()
    }

    func reloadData() {
        let selectedID = selectedRecordID()
        let result = store.fetchEntries(search: currentSearch())
        records = result.records
        tableView.reloadData()
        emptyLabel.isHidden = !records.isEmpty
        queryStatusLabel.stringValue = result.error ?? ""
        queryStatusLabel.isHidden = result.error == nil
        restoreSelection(preferredID: selectedID)
    }

    func setCapturePaused(_ paused: Bool) {
        captureStatusLabel.stringValue = paused ? "Capture paused in settings" : ""
        captureStatusLabel.isHidden = !paused
    }

    func controlTextDidChange(_ obj: Notification) {
        reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        records.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        64
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipCell")
        let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? ClipCellView) ?? ClipCellView(frame: .zero)
        cell.identifier = identifier
        cell.configure(with: records[row], index: row)
        return cell
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

        searchField.placeholderString = "Search text or use type:, app:, after:, encrypted:, image:"
        searchField.delegate = self
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
        queryStatusLabel.isHidden = true
        queryStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("clip"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowSizeStyle = .default
        tableView.intercellSpacing = NSSize(width: 0, height: 6)
        tableView.allowsEmptySelection = false
        tableView.focusRingType = .none
        tableView.doubleAction = #selector(activateSelection)
        tableView.target = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(searchField)
        contentView.addSubview(hintLabel)
        contentView.addSubview(captureStatusLabel)
        contentView.addSubview(queryStatusLabel)
        contentView.addSubview(scrollView)
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            hintLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),
            hintLabel.trailingAnchor.constraint(lessThanOrEqualTo: searchField.trailingAnchor),

            captureStatusLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 6),
            captureStatusLabel.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),

            queryStatusLabel.centerYAnchor.constraint(equalTo: captureStatusLabel.centerYAnchor),
            queryStatusLabel.trailingAnchor.constraint(equalTo: searchField.trailingAnchor),
            queryStatusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: captureStatusLabel.trailingAnchor, constant: 12),

            scrollView.topAnchor.constraint(equalTo: captureStatusLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
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
        guard let window,
              window.isVisible,
              window.isKeyWindow else {
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
    }

    private func chooseRow(at index: Int) {
        guard index >= 0, index < records.count else {
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        activateSelection()
    }

    private func selectedRecordID() -> String? {
        guard tableView.selectedRow >= 0, tableView.selectedRow < records.count else {
            return nil
        }
        return records[tableView.selectedRow].id
    }

    private func restoreSelection(preferredID: String?) {
        guard !records.isEmpty else {
            return
        }

        if let preferredID,
           let row = records.firstIndex(where: { $0.id == preferredID }) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.scrollRowToVisible(row)
            return
        }

        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
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

private final class ClipCellView: NSTableCellView {
    private let indexLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let previewImageView = NSImageView(frame: .zero)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with record: ClipRecord, index: Int) {
        indexLabel.stringValue = index < 10 ? "\(index == 9 ? 0 : index + 1)." : ""
        titleLabel.stringValue = record.titleText
        detailLabel.stringValue = record.detailText
        previewImageView.image = record.previewImage
        previewImageView.isHidden = record.previewImage == nil
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

        previewImageView.imageScaling = .scaleProportionallyUpOrDown
        previewImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(indexLabel)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(previewImageView)

        NSLayoutConstraint.activate([
            indexLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            indexLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            indexLabel.widthAnchor.constraint(equalToConstant: 24),

            previewImageView.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 8),
            previewImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            previewImageView.widthAnchor.constraint(equalToConstant: 48),
            previewImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }
}
