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

    private var records: [ClipRecord] = []

    init(store: Store, onChooseRecord: @escaping (ClipRecord) -> Void) {
        self.store = store
        self.onChooseRecord = onChooseRecord

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Clipboard History"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace]
        panel.minSize = NSSize(width: 420, height: 260)

        super.init(window: panel)
        buildUI()
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
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        searchField.becomeFirstResponder()
    }

    func reloadData() {
        records = store.fetchEntries(search: currentSearch())
        tableView.reloadData()
        emptyLabel.isHidden = !records.isEmpty
        if !records.isEmpty, tableView.selectedRow == -1 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }

    func controlTextDidChange(_ obj: Notification) {
        reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        records.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        58
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipCell")
        let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? ClipCellView) ?? ClipCellView(frame: .zero)
        cell.identifier = identifier
        cell.configure(with: records[row])
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

        searchField.placeholderString = "Search history"
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false

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
        contentView.addSubview(scrollView)
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            emptyLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
    }

    private func currentSearch() -> String? {
        let value = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

final class ClipCellView: NSTableCellView {
    private let thumbnailView = NSImageView(frame: .zero)
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        thumbnailView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = NSFont.systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(thumbnailView)
        addSubview(titleLabel)
        addSubview(detailLabel)

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 36),
            thumbnailView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with record: ClipRecord) {
        titleLabel.stringValue = record.titleText
        detailLabel.stringValue = record.detailText
        if let image = record.previewImage {
            thumbnailView.image = image
            thumbnailView.contentTintColor = nil
        } else {
            thumbnailView.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: nil)
            thumbnailView.contentTintColor = .secondaryLabelColor
        }
    }
}
