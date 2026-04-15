import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store?
    private var poller: ClipboardPoller?
    private var hotkeyManager: HotkeyManager?
    private var historyWindow: HistoryWindowController?
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let store = try Store(maxEntries: 200)
            self.store = store

            let historyWindow = HistoryWindowController(store: store) { [weak self] record in
                self?.copy(record)
            }
            self.historyWindow = historyWindow

            let poller = ClipboardPoller(store: store)
            poller.onNewRecord = { [weak historyWindow] _ in
                historyWindow?.reloadData()
            }
            poller.start()
            self.poller = poller

            let hotkeyManager = try HotkeyManager()
            hotkeyManager.onHotkey = { [weak self] in
                self?.toggleHistoryWindow()
            }
            self.hotkeyManager = hotkeyManager

            menuBar = MenuBarController(
                openHistory: { [weak self] in self?.toggleHistoryWindow() },
                quitApp: { NSApp.terminate(nil) }
            )
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "clip-01 failed to start"
            alert.informativeText = "The local clipboard store could not be initialized."
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

    private func copy(_ record: ClipRecord) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch record.kind {
        case .text:
            if let text = record.textValue {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let payload = record.payload, let image = NSImage(data: payload) {
                pasteboard.writeObjects([image])
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
