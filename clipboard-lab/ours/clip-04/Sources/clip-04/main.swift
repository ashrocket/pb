import AppKit
import Foundation
import ServiceManagement

enum LoginItemManager {
    static func sync(enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            return
        }

        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else if service.status == .enabled {
                try service.unregister()
            }
        } catch {
            // Login item failures must not leak clipboard data.
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var configController: ConfigController?
    private var historyWindow: HistoryWindowController?
    private var hotkeyManager: HotkeyManager?
    private var menuBar: MenuBarController?
    private var poller: ClipboardPoller?
    private var settingsWindow: SettingsWindowController?
    private var store: Store?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let configController = try ConfigController()
            self.configController = configController

            let encryptionManager = EncryptionManager()
            let store = try Store(configuration: configController.currentConfiguration, encryptionManager: encryptionManager)
            self.store = store

            let historyWindow = HistoryWindowController(store: store) { [weak self] record in
                self?.copy(record)
            }
            self.historyWindow = historyWindow

            let settingsWindow = SettingsWindowController(
                configuration: configController.currentConfiguration,
                configURL: configController.configURL,
                onSave: { [weak configController] configuration in
                    guard let configController else {
                        return
                    }
                    try configController.save(configuration)
                },
                onReload: { [weak configController] in
                    configController?.reloadFromDisk()
                },
                onRevealConfig: { [weak configController] in
                    configController?.revealInFinder()
                }
            )
            self.settingsWindow = settingsWindow

            let poller = ClipboardPoller(store: store, configuration: configController.currentConfiguration)
            poller.onNewRecord = { [weak historyWindow] _ in
                historyWindow?.reloadData()
            }
            poller.start()
            self.poller = poller

            let hotkeyManager = try HotkeyManager(configuration: configController.currentConfiguration)
            hotkeyManager.onHotkey = { [weak self] in
                self?.toggleHistoryWindow()
            }
            self.hotkeyManager = hotkeyManager

            let menuBar = MenuBarController(
                openHistory: { [weak self] in self?.toggleHistoryWindow() },
                openSettings: { [weak self] in self?.showSettingsWindow() },
                quitApp: { NSApp.terminate(nil) }
            )
            self.menuBar = menuBar

            configController.onChange = { [weak self] configuration in
                self?.apply(configuration)
            }
            configController.startMonitoring()
            apply(configController.currentConfiguration)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Clipboard History failed to start"
            alert.informativeText = "The local store, config file, or encryption key could not be initialized."
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func toggleHistoryWindow() {
        historyWindow?.toggle()
    }

    private func showSettingsWindow() {
        settingsWindow?.show()
    }

    private func apply(_ configuration: ClipConfiguration) {
        store?.applyConfiguration(configuration)
        poller?.applyConfiguration(configuration)
        try? hotkeyManager?.applyConfiguration(configuration)
        LoginItemManager.sync(enabled: configuration.autoStartAtLogin)
        historyWindow?.setCapturePaused(configuration.pauseCapture)
        historyWindow?.reloadData()
        menuBar?.updateCapturePaused(configuration.pauseCapture)
        settingsWindow?.apply(configuration)
    }

    private func copy(_ record: ClipRecord) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch record.kind {
        case .text, .url:
            if let text = record.textValue {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let payload = record.payload, let image = NSImage(data: payload) {
                pasteboard.writeObjects([image])
            }
        }

        poller?.ignoreCurrentPasteboardState()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
