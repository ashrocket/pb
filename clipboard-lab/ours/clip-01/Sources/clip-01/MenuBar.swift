import AppKit
import Foundation

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let openHistory: () -> Void
    private let quitApp: () -> Void
    private let menu = NSMenu()

    init(openHistory: @escaping () -> Void, quitApp: @escaping () -> Void) {
        self.openHistory = openHistory
        self.quitApp = quitApp
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configure()
    }

    private func configure() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard History")
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu.addItem(withTitle: "Open History", action: #selector(openHistoryFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(sender)
            statusItem.menu = nil
            return
        }
        openHistory()
    }

    @objc private func openHistoryFromMenu() {
        openHistory()
    }

    @objc private func quitFromMenu() {
        quitApp()
    }
}
