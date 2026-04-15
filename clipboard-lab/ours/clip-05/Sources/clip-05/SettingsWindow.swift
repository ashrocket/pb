import AppKit
import Foundation

@MainActor
final class SettingsWindowController: NSWindowController {
    private let onSave: (ClipConfiguration) throws -> Void
    private let onReload: () -> Void
    private let onRevealConfig: () -> Void

    private let autoStartCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
    private let pauseCheckbox = NSButton(checkboxWithTitle: "Pause clipboard capture", target: nil, action: nil)
    private let historyCountField = NSTextField(frame: .zero)
    private let historyCountStepper = NSStepper(frame: .zero)
    private let maxBytesField = NSTextField(frame: .zero)
    private let maxBytesStepper = NSStepper(frame: .zero)
    private let pollingIntervalField = NSTextField(frame: .zero)
    private let hotkeyPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let excludedAppsTextView = NSTextView(frame: .zero)
    private let configPathField = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")

    init(
        configuration: ClipConfiguration,
        configURL: URL,
        onSave: @escaping (ClipConfiguration) throws -> Void,
        onReload: @escaping () -> Void,
        onRevealConfig: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onReload = onReload
        self.onRevealConfig = onRevealConfig

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()

        super.init(window: window)
        buildUI(configURL: configURL)
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func apply(_ configuration: ClipConfiguration) {
        autoStartCheckbox.state = configuration.autoStartAtLogin ? .on : .off
        pauseCheckbox.state = configuration.pauseCapture ? .on : .off
        historyCountField.stringValue = String(configuration.historyRetentionCount)
        historyCountStepper.integerValue = configuration.historyRetentionCount
        maxBytesField.stringValue = String(configuration.maxBytesPerClip)
        maxBytesStepper.integerValue = configuration.maxBytesPerClip
        pollingIntervalField.stringValue = String(format: "%.2f", configuration.pollingIntervalSeconds)

        if let index = HotkeyModifierPreset.allCases.firstIndex(of: configuration.hotkeyModifiers) {
            hotkeyPopup.selectItem(at: index)
        }

        excludedAppsTextView.string = configuration.excludedBundleIDs.joined(separator: "\n")
    }

    private func buildUI(configURL: URL) {
        guard let contentView = window?.contentView else {
            return
        }

        let padding: CGFloat = 20

        let rootStack = NSStackView()
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 14
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        let toggleStack = NSStackView(views: [pauseCheckbox, autoStartCheckbox])
        toggleStack.orientation = .vertical
        toggleStack.alignment = .leading
        toggleStack.spacing = 8

        [pauseCheckbox, autoStartCheckbox].forEach {
            $0.target = self
            $0.action = #selector(clearStatus)
        }

        configureIntegerField(historyCountField)
        configureIntegerField(maxBytesField)
        configureDecimalField(pollingIntervalField)

        configureStepper(historyCountStepper, minValue: 1, maxValue: 5_000, increment: 10, action: #selector(historyStepperChanged(_:)))
        configureStepper(maxBytesStepper, minValue: 1, maxValue: 100_000_000, increment: 1024, action: #selector(maxBytesStepperChanged(_:)))

        hotkeyPopup.addItems(withTitles: HotkeyModifierPreset.allCases.map(\.displayName))
        hotkeyPopup.target = self
        hotkeyPopup.action = #selector(clearStatus)

        excludedAppsTextView.isRichText = false
        excludedAppsTextView.isAutomaticQuoteSubstitutionEnabled = false
        excludedAppsTextView.isAutomaticDataDetectionEnabled = false
        excludedAppsTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        excludedAppsTextView.allowsUndo = true

        let excludedAppsScrollView = NSScrollView()
        excludedAppsScrollView.borderType = .bezelBorder
        excludedAppsScrollView.hasVerticalScroller = true
        excludedAppsScrollView.documentView = excludedAppsTextView
        excludedAppsScrollView.translatesAutoresizingMaskIntoConstraints = false
        excludedAppsScrollView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        excludedAppsScrollView.widthAnchor.constraint(equalToConstant: 420).isActive = true

        configPathField.stringValue = configURL.path
        configPathField.lineBreakMode = .byTruncatingMiddle

        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor

        let historyRow = horizontalStack([historyCountField, historyCountStepper])
        let maxBytesRow = horizontalStack([maxBytesField, maxBytesStepper])

        let form = NSGridView(views: [
            [labelField("History retention count"), historyRow],
            [labelField("Max bytes per clip"), maxBytesRow],
            [labelField("Polling interval"), pollingIntervalField],
            [labelField("Hotkey"), hotkeyPopup],
            [labelField("Excluded bundle IDs"), excludedAppsScrollView],
            [labelField("Config file"), configPathField]
        ])
        form.rowSpacing = 12
        form.columnSpacing = 16
        form.translatesAutoresizingMaskIntoConstraints = false
        form.row(at: 4).yPlacement = .top

        let hints = NSStackView(views: [
            hintField("Polling is in seconds. Values below 0.10 are clamped."),
            hintField("Enter one bundle ID per line, for example `com.apple.KeychainAccess`."),
            hintField("The hotkey always uses the V key; this setting changes only the modifier set.")
        ])
        hints.orientation = .vertical
        hints.alignment = .leading
        hints.spacing = 4

        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePressed))
        saveButton.keyEquivalent = "\r"

        let reloadButton = NSButton(title: "Reload", target: self, action: #selector(reloadPressed))
        let revealButton = NSButton(title: "Reveal Config", target: self, action: #selector(revealPressed))

        let actionRow = NSStackView(views: [statusLabel, NSView(), saveButton, reloadButton, revealButton])
        actionRow.orientation = .horizontal
        actionRow.alignment = .centerY
        actionRow.spacing = 10
        actionRow.translatesAutoresizingMaskIntoConstraints = false

        rootStack.addArrangedSubview(toggleStack)
        rootStack.addArrangedSubview(form)
        rootStack.addArrangedSubview(hints)
        rootStack.addArrangedSubview(actionRow)

        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding),

            historyCountField.widthAnchor.constraint(equalToConstant: 120),
            maxBytesField.widthAnchor.constraint(equalToConstant: 120),
            pollingIntervalField.widthAnchor.constraint(equalToConstant: 120),
            configPathField.widthAnchor.constraint(greaterThanOrEqualToConstant: 420)
        ])
    }

    @objc private func historyStepperChanged(_ sender: NSStepper) {
        historyCountField.stringValue = String(sender.integerValue)
        clearStatus()
    }

    @objc private func maxBytesStepperChanged(_ sender: NSStepper) {
        maxBytesField.stringValue = String(sender.integerValue)
        clearStatus()
    }

    @objc private func savePressed() {
        do {
            try onSave(readConfiguration())
            statusLabel.stringValue = "Saved to config.toml"
            statusLabel.textColor = .systemGreen
        } catch let error as SettingsValidationError {
            statusLabel.stringValue = error.message
            statusLabel.textColor = .systemRed
        } catch {
            statusLabel.stringValue = "Could not save settings."
            statusLabel.textColor = .systemRed
        }
    }

    @objc private func reloadPressed() {
        onReload()
        statusLabel.stringValue = "Reloaded from config.toml"
        statusLabel.textColor = .secondaryLabelColor
    }

    @objc private func revealPressed() {
        onRevealConfig()
    }

    @objc private func clearStatus() {
        statusLabel.stringValue = ""
    }

    private func readConfiguration() throws -> ClipConfiguration {
        let historyCount = historyCountField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedHistoryCount = Int(historyCount), parsedHistoryCount > 0 else {
            throw SettingsValidationError.invalidHistoryCount
        }

        let maxBytes = maxBytesField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedMaxBytes = Int(maxBytes), parsedMaxBytes > 0 else {
            throw SettingsValidationError.invalidMaxBytes
        }

        let polling = pollingIntervalField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedPolling = Double(polling), parsedPolling >= 0.1 else {
            throw SettingsValidationError.invalidPollingInterval
        }

        let hotkeyModifiers = HotkeyModifierPreset.allCases[safe: hotkeyPopup.indexOfSelectedItem] ?? .commandShift

        let excludedApps = excludedAppsTextView.string
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()

        return ClipConfiguration(
            autoStartAtLogin: autoStartCheckbox.state == .on,
            excludedBundleIDs: excludedApps,
            historyRetentionCount: parsedHistoryCount,
            hotkeyModifiers: hotkeyModifiers,
            maxBytesPerClip: parsedMaxBytes,
            pauseCapture: pauseCheckbox.state == .on,
            pollingIntervalSeconds: parsedPolling
        )
    }

    private func configureDecimalField(_ field: NSTextField) {
        field.alignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        field.target = self
        field.action = #selector(clearStatus)
    }

    private func configureIntegerField(_ field: NSTextField) {
        field.alignment = .right
        field.translatesAutoresizingMaskIntoConstraints = false
        field.target = self
        field.action = #selector(clearStatus)
    }

    private func configureStepper(_ stepper: NSStepper, minValue: Double, maxValue: Double, increment: Double, action: Selector) {
        stepper.minValue = minValue
        stepper.maxValue = maxValue
        stepper.increment = increment
        stepper.target = self
        stepper.action = action
        stepper.translatesAutoresizingMaskIntoConstraints = false
    }

    private func horizontalStack(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 10
        return stack
    }

    private func labelField(_ string: String) -> NSTextField {
        let field = NSTextField(labelWithString: string)
        field.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        return field
    }

    private func hintField(_ string: String) -> NSTextField {
        let field = NSTextField(labelWithString: string)
        field.font = NSFont.systemFont(ofSize: 11)
        field.textColor = .secondaryLabelColor
        return field
    }
}

private enum SettingsValidationError: Error {
    case invalidHistoryCount
    case invalidMaxBytes
    case invalidPollingInterval

    var message: String {
        switch self {
        case .invalidHistoryCount:
            return "History retention count must be a positive integer."
        case .invalidMaxBytes:
            return "Max bytes per clip must be a positive integer."
        case .invalidPollingInterval:
            return "Polling interval must be at least 0.10 seconds."
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
