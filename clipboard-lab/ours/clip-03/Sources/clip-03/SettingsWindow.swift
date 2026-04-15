import AppKit
import Foundation

@MainActor
final class SettingsWindowController: NSWindowController {
    private let onSave: (ClipConfiguration) throws -> Void
    private let onReload: () -> Void
    private let onRevealConfig: () -> Void

    private let pauseCheckbox = NSButton(checkboxWithTitle: "Pause clipboard capture", target: nil, action: nil)
    private let maxBytesField = NSTextField(frame: .zero)
    private let maxBytesStepper = NSStepper(frame: .zero)
    private let excludedAppsField = NSTextField(frame: .zero)
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
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 280),
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
        pauseCheckbox.state = configuration.pauseCapture ? .on : .off
        maxBytesField.stringValue = String(configuration.maxBytesPerClip)
        maxBytesStepper.integerValue = configuration.maxBytesPerClip
        excludedAppsField.stringValue = configuration.excludedBundleIDs.joined(separator: ", ")
    }

    private func buildUI(configURL: URL) {
        guard let contentView = window?.contentView else {
            return
        }

        let padding: CGFloat = 20
        let labelWidth: CGFloat = 150

        let maxBytesLabel = labelField("Max bytes per clip")
        let excludedLabel = labelField("Excluded bundle IDs")
        let configLabel = labelField("Config file")
        let excludedHint = hintField("Comma-separated bundle IDs, for example com.apple.KeychainAccess")

        pauseCheckbox.target = self
        pauseCheckbox.action = #selector(clearStatus)
        pauseCheckbox.translatesAutoresizingMaskIntoConstraints = false

        maxBytesField.placeholderString = "1048576"
        maxBytesField.alignment = .right
        maxBytesField.translatesAutoresizingMaskIntoConstraints = false
        maxBytesField.target = self
        maxBytesField.action = #selector(clearStatus)

        maxBytesStepper.minValue = 1
        maxBytesStepper.maxValue = 100_000_000
        maxBytesStepper.increment = 1024
        maxBytesStepper.target = self
        maxBytesStepper.action = #selector(stepperChanged(_:))
        maxBytesStepper.translatesAutoresizingMaskIntoConstraints = false

        excludedAppsField.placeholderString = "com.apple.Safari, com.apple.KeychainAccess"
        excludedAppsField.translatesAutoresizingMaskIntoConstraints = false
        excludedAppsField.target = self
        excludedAppsField.action = #selector(clearStatus)

        configPathField.stringValue = configURL.path
        configPathField.lineBreakMode = .byTruncatingMiddle
        configPathField.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePressed))
        saveButton.keyEquivalent = "\r"
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        let reloadButton = NSButton(title: "Reload", target: self, action: #selector(reloadPressed))
        reloadButton.translatesAutoresizingMaskIntoConstraints = false

        let revealButton = NSButton(title: "Reveal Config", target: self, action: #selector(revealPressed))
        revealButton.translatesAutoresizingMaskIntoConstraints = false

        [maxBytesLabel, excludedLabel, configLabel, excludedHint].forEach { contentView.addSubview($0) }
        [pauseCheckbox, maxBytesField, maxBytesStepper, excludedAppsField, configPathField, statusLabel, saveButton, reloadButton, revealButton]
            .forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            pauseCheckbox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            pauseCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            pauseCheckbox.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -padding),

            maxBytesLabel.topAnchor.constraint(equalTo: pauseCheckbox.bottomAnchor, constant: 22),
            maxBytesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            maxBytesLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            maxBytesField.centerYAnchor.constraint(equalTo: maxBytesLabel.centerYAnchor),
            maxBytesField.leadingAnchor.constraint(equalTo: maxBytesLabel.trailingAnchor, constant: 12),
            maxBytesField.widthAnchor.constraint(equalToConstant: 120),

            maxBytesStepper.centerYAnchor.constraint(equalTo: maxBytesField.centerYAnchor),
            maxBytesStepper.leadingAnchor.constraint(equalTo: maxBytesField.trailingAnchor, constant: 12),

            excludedLabel.topAnchor.constraint(equalTo: maxBytesLabel.bottomAnchor, constant: 20),
            excludedLabel.leadingAnchor.constraint(equalTo: maxBytesLabel.leadingAnchor),
            excludedLabel.widthAnchor.constraint(equalTo: maxBytesLabel.widthAnchor),

            excludedAppsField.centerYAnchor.constraint(equalTo: excludedLabel.centerYAnchor),
            excludedAppsField.leadingAnchor.constraint(equalTo: excludedLabel.trailingAnchor, constant: 12),
            excludedAppsField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            excludedHint.topAnchor.constraint(equalTo: excludedAppsField.bottomAnchor, constant: 6),
            excludedHint.leadingAnchor.constraint(equalTo: excludedAppsField.leadingAnchor),
            excludedHint.trailingAnchor.constraint(equalTo: excludedAppsField.trailingAnchor),

            configLabel.topAnchor.constraint(equalTo: excludedHint.bottomAnchor, constant: 20),
            configLabel.leadingAnchor.constraint(equalTo: excludedLabel.leadingAnchor),
            configLabel.widthAnchor.constraint(equalTo: excludedLabel.widthAnchor),

            configPathField.centerYAnchor.constraint(equalTo: configLabel.centerYAnchor),
            configPathField.leadingAnchor.constraint(equalTo: configLabel.trailingAnchor, constant: 12),
            configPathField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: reloadButton.leadingAnchor, constant: -12),

            revealButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            revealButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),

            reloadButton.trailingAnchor.constraint(equalTo: revealButton.leadingAnchor, constant: -10),
            reloadButton.centerYAnchor.constraint(equalTo: revealButton.centerYAnchor),

            saveButton.trailingAnchor.constraint(equalTo: reloadButton.leadingAnchor, constant: -10),
            saveButton.centerYAnchor.constraint(equalTo: revealButton.centerYAnchor)
        ])
    }

    @objc private func stepperChanged(_ sender: NSStepper) {
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
        let maxBytes = maxBytesField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedMaxBytes = Int(maxBytes), parsedMaxBytes > 0 else {
            throw SettingsValidationError.invalidMaxBytes
        }

        let excludedApps = excludedAppsField.stringValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()

        return ClipConfiguration(
            excludedBundleIDs: excludedApps,
            maxBytesPerClip: parsedMaxBytes,
            pauseCapture: pauseCheckbox.state == .on
        )
    }

    private func labelField(_ string: String) -> NSTextField {
        let field = NSTextField(labelWithString: string)
        field.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }

    private func hintField(_ string: String) -> NSTextField {
        let field = NSTextField(labelWithString: string)
        field.font = NSFont.systemFont(ofSize: 11)
        field.textColor = .secondaryLabelColor
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }
}

private enum SettingsValidationError: Error {
    case invalidMaxBytes

    var message: String {
        switch self {
        case .invalidMaxBytes:
            return "Max bytes per clip must be a positive integer."
        }
    }
}
